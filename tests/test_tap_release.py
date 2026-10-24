import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import zipfile
import tempfile

spec = importlib.util.spec_from_file_location('tap_release', Path(__file__).parents[1] / 'scripts/tap_release.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
ROOT = Path(__file__).parents[1]


class PolicyTests(unittest.TestCase):
    def text(self, package):
        return (ROOT / m.PRODUCTS[package][1]).read_text()

    def bump(self, package):
        before = self.text(package)
        old = m.version(before, package)
        new = old.rsplit('.', 1)[0] + '.' + str(int(old.split('.')[-1]) + 1)
        after = before.replace(old, new)
        return before, after, new

    def test_all_three_version_updates(self):
        for p in m.PRODUCTS:
            with self.subTest(p=p):
                before, after, new = self.bump(p)
                self.assertEqual(m.validate_change(p, before, after), new)

    def test_dependency_or_install_changes_rejected(self):
        for p in m.PRODUCTS:
            before, after, _ = self.bump(p)
            with self.assertRaises(ValueError):
                m.validate_change(p, before, after + '\n  system "malicious"\n')

    def test_same_version_or_downgrade_rejected(self):
        for p in m.PRODUCTS:
            before, after, _ = self.bump(p)
            for old, new in [(before, before), (after, before)]:
                with self.assertRaises(ValueError):
                    m.validate_change(p, old, new)

    def test_duplicate_sha_rejected(self):
        before, after, _ = self.bump('minitools')
        after += '\n  sha256 "' + 'a' * 64 + '"\n'
        with self.assertRaises(ValueError):
            m.validate_change('minitools', before, after)

    def test_bundle_id_changes_rejected(self):
        before, after, _ = self.bump('minitools')
        with self.assertRaises(ValueError):
            m.validate_change('minitools', before, after.replace('com.omzcj.minitools', 'other.id'))

    def test_pr_from_fork_or_other_author_not_automatic(self):
        pr = {'head': {'repo': {'full_name': 'other/fork'}, 'ref': 'bump-omcli-1'}, 'user': {'login': m.OWNER}, 'base': {'ref': 'main'}}
        self.assertIsNone(m.candidate(pr))
        pr['head']['repo']['full_name'] = m.REPO
        pr['user']['login'] = 'stranger'
        self.assertIsNone(m.candidate(pr))

    def test_scaletail_is_manual(self):
        pr = {'head': {'repo': {'full_name': m.REPO}, 'ref': 'bump-scaletail-1'}, 'user': {'login': m.OWNER}, 'base': {'ref': 'main'}}
        self.assertIsNone(m.candidate(pr))

    def test_missing_or_wrong_asset_digest_rejected(self):
        release = {'assets': [{'name': 'x', 'state': 'uploaded', 'size': 1, 'digest': 'sha256:' + 'a' * 64}]}
        self.assertEqual(m.asset(release, 'x', 'a' * 64)['name'], 'x')
        with self.assertRaises(ValueError):
            m.asset(release, 'missing')
        with self.assertRaises(ValueError):
            m.asset(release, 'x', 'b' * 64)
        release['assets'][0]['digest'] = None
        with self.assertRaises(ValueError):
            m.asset(release, 'x')

    def test_old_bottle_blocks_first_round(self):
        text = self.text('omcli')
        with self.assertRaisesRegex(ValueError, 'Waiting for'):
            m.bottle_ready(text, {'assets': []}, '2099.01.01.1')

    def test_missing_bottle_blocks_merge(self):
        text = self.text('omcli')
        with self.assertRaisesRegex(ValueError, 'Missing unique asset'):
            m.bottle_ready(text, {'assets': []}, m.version(text, 'omcli'))

    def test_valid_bottle_and_extra_directives(self):
        text = self.text('omcli')
        ver = m.version(text, 'omcli')
        sha = m.one(r'    sha256 cellar: :any_skip_relocation, arm64_tahoe: "([0-9a-f]+)"', text)[1]
        release = {'assets': [{'name': f'omcli-{ver}.arm64_tahoe.bottle.tar.gz', 'state': 'uploaded', 'size': 10, 'digest': 'sha256:' + sha}]}
        m.bottle_ready(text, release, ver)
        with self.assertRaises(ValueError):
            m.bottle_ready(text.replace('  bottle do', '  bottle do\n    system "bad"'), release, ver)

    @patch.object(m, 'api')
    def test_changed_head_rejected(self, api):
        api.return_value = {'head': {'sha': 'new'}}
        with self.assertRaisesRegex(ValueError, 'head changed'):
            m.gate(1, 'old')

    @patch.object(m, 'latest')
    def test_new_stable_supersedes_candidate(self, latest):
        latest.return_value = {'tag_name': 'v2099.01.01.1'}
        with self.assertRaisesRegex(ValueError, 'superseded'):
            m.verify_release('omcli', '2026.10.16.1', self.text('omcli'))

    def test_zip_traversal_and_symlink_escape_rejected(self):
        for filename, target in [('../escape', None), ('App.app/link', '../../escape')]:
            with tempfile.TemporaryDirectory() as d:
                path = Path(d) / 'test.zip'
                with zipfile.ZipFile(path, 'w') as z:
                    info = zipfile.ZipInfo(filename)
                    if target:
                        info.external_attr = 0o120777 << 16
                    z.writestr(info, target or 'x')
                with self.assertRaises(ValueError):
                    m.safe_zip(path)

    @patch.object(m, 'content')
    @patch.object(m, 'api')
    def test_mixed_file_pr_rejected(self, api, content):
        pr = {'number': 1, 'state': 'open', 'draft': False, 'user': {'login': m.OWNER},
              'head': {'repo': {'full_name': m.REPO}, 'ref': 'bump-minitools-2026.10.20.7'}, 'base': {'ref': 'main'}}
        api.return_value = [{'filename': 'Casks/minitools.rb'}, {'filename': '.github/workflows/evil.yml'}]
        with self.assertRaisesRegex(ValueError, 'only its package'):
            m.candidate(pr)
        content.assert_not_called()


class ReconcileTests(unittest.TestCase):
    def pr(self):
        return {'number': 62, 'head': {'ref': 'bump-omcli-2026.10.20.1', 'sha': 'old'}, 'state': 'open'}

    @patch.object(m, 'asset')
    @patch.object(m, 'content', return_value='source')
    @patch.object(m, 'version', return_value='2026.10.16.1')
    @patch.object(m, 'candidate', return_value=('omcli', '2026.10.20.1', 'source'))
    @patch.object(m, 'latest', return_value={'tag_name': 'v2026.10.21.1', 'html_url': 'https://example/release'})
    @patch.object(m, 'run')
    @patch.object(m, 'api')
    def test_stale_pr_is_closed_without_rewriting_branch(self, api, run, *_):
        with patch.dict(m.PRODUCTS, {'omcli': ('omcli', 'Formula/omcli.rb')}, clear=True):
            api.side_effect = [[self.pr()], self.pr()]
            m.reconcile()
        self.assertEqual(run.call_args.args[:4], ('gh', 'pr', 'close', '62'))
        self.assertNotIn('--delete-branch', run.call_args.args)

    @patch.object(m, 'asset')
    @patch.object(m, 'content', return_value='source')
    @patch.object(m, 'version', return_value='2026.10.16.1')
    @patch.object(m, 'candidate', side_effect=ValueError('mixed changes'))
    @patch.object(m, 'latest', return_value={'tag_name': 'v2026.10.21.1'})
    @patch.object(m, 'run')
    @patch.object(m, 'api')
    def test_mixed_stale_pr_preserved(self, api, run, *_):
        api.return_value = [self.pr()]
        with patch.dict(m.PRODUCTS, {'omcli': ('omcli', 'Formula/omcli.rb')}, clear=True):
            with self.assertRaisesRegex(ValueError, 'mixed changes'):
                m.reconcile()
        run.assert_not_called()

    @patch.object(m, 'asset')
    @patch.object(m, 'content', return_value='source')
    @patch.object(m, 'version', return_value='2026.10.16.1')
    @patch.object(m, 'latest', return_value={'tag_name': 'v2026.10.21.1'})
    @patch.object(m, 'api', return_value=[])
    def test_missing_latest_pr_fails_report(self, *_):
        with patch.dict(m.PRODUCTS, {'omcli': ('omcli', 'Formula/omcli.rb')}, clear=True):
            with self.assertRaisesRegex(ValueError, 'No PR for latest'):
                m.reconcile(report=True)

    @patch.object(m, 'candidate', return_value=('omcli', '2026.10.21.1', 'source'))
    @patch.object(m, 'latest', return_value={'tag_name': 'v2026.10.21.1'})
    @patch.object(m, 'api')
    @patch.object(m, 'run')
    def test_main_advance_updates_branch_with_expected_sha(self, run, api, *_):
        pr = self.pr()
        fresh = dict(pr, mergeable_state='behind')
        api.side_effect = [[pr], fresh, {}]
        m.sync()
        self.assertEqual(api.call_args.args, ('pulls/62/update-branch', 'PUT', {'expected_head_sha': 'old'}))
        run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
