#!/usr/bin/env python3
"""Trusted Tap release policy. Never evaluates Ruby or checks out PR code."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

REPO = "oh-my-brew/homebrew-tap"
OWNER = "assassinor"  # identity used by HOMEBREW_BUMP_TOKEN
TEAM = "566UG6DQ7E"
SPARKLE_KEY = "SI7Q1gbm7r8+v3VnFtR3kELRiKtZ7OMQIFKfaqpwvhA="
PRODUCTS = {
    "omcli": ("omcli", "Formula/omcli.rb"),
    "minitools": ("miniTools", "Casks/minitools.rb"),
    "rustdeskx": ("rustdeskx", "Casks/rustdeskx.rb"),
}
HEX = r"[0-9a-f]{64}"
BOTTLE = r'^  bottle do\n(?:    .*\n)+?  end\n'


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def api(path, method="GET", payload=None):
    args = ["gh", "api", f"repos/{REPO}/{path}" if not path.startswith("/") else path[1:]]
    if method != "GET":
        args += ["--method", method]
    if payload is not None:
        args += ["--input", "-"]
    return json.loads(subprocess.check_output(args, input=json.dumps(payload) if payload is not None else None, text=True))


def require(value, message):
    if not value:
        raise ValueError(message)


def one(pattern, text):
    matches = list(re.finditer(pattern, text, re.M))
    require(len(matches) == 1, f"Expected exactly one field: {pattern}")
    return matches[0]


def version(text, package):
    if package == "omcli":
        return one(r'^  url "https://github.com/oh-my-brew/omcli/releases/download/v([0-9.]+)/omcli-\1.tar.gz"$', text)[1]
    return one(r'^  version "([0-9.]+)"$', text)[1]


def normalize(text, package):
    fields = [(rf'^  sha256 "{HEX}"$', '  sha256 "SOURCE_SHA"')]
    if package == "omcli":
        fields += [(r'^  url "https://github.com/oh-my-brew/omcli/releases/download/v([0-9.]+)/omcli-\1.tar.gz"$', '  url "SOURCE_URL"'),
                   (BOTTLE, '  bottle do\n    BOTTLE\n  end\n')]
    else:
        fields += [(r'^  version "[0-9.]+"$', '  version "VERSION"')]
    for pattern, replacement in fields:
        one(pattern, text)
        text = re.sub(pattern, replacement, text, flags=re.M)
    return text


def validate_change(package, before, after):
    require(normalize(before, package) == normalize(after, package), "Changes outside version, URL, SHA or bottle")
    old, new = version(before, package), version(after, package)
    require(tuple(map(int, new.split('.'))) > tuple(map(int, old.split('.'))), "Version must increase")
    if package != "rustdeskx":
        require(re.fullmatch(r'\d{4}\.\d{2}\.\d{2}\.[1-9]\d*', new), "Invalid calendar version")
    else:
        require(re.fullmatch(r'\d+\.\d+\.\d+\.[1-9]\d*', new), "Invalid RustDeskX version")
    return new


def content(path, ref):
    return base64.b64decode(api(f"contents/{path}?ref={ref}")["content"]).decode()


def candidate(pr):
    if pr["head"]["repo"] is None or pr["head"]["repo"]["full_name"] != REPO:
        return None
    branch = pr["head"]["ref"]
    package = next((p for p in PRODUCTS if branch.startswith(f"bump-{p}-")), None)
    if package is None or pr["user"]["login"] != OWNER or pr["base"]["ref"] != "main":
        return None
    require(pr["state"] == "open" and not pr["draft"], "PR must be open and ready")
    files = api(f"pulls/{pr['number']}/files?per_page=100")
    path = PRODUCTS[package][1]
    require(len(files) == 1 and files[0]["filename"] == path and files[0]["status"] == "modified", "PR must modify only its package")
    before = content(path, pr["base"]["sha"])
    after = content(path, pr["head"]["sha"])
    ver = validate_change(package, before, after)
    require(branch == f"bump-{package}-{ver}", "Branch must match exact package version")
    return package, ver, after


def latest(package):
    product = PRODUCTS[package][0]
    release = api(f"/repos/oh-my-brew/{product}/releases/latest")
    require(not release["draft"] and not release["prerelease"], "Expected stable published Release")
    return release


def asset(release, name, expected=None):
    matches = [a for a in release["assets"] if a["name"] == name]
    require(len(matches) == 1, f"Missing unique asset {name}")
    result = matches[0]
    require(result["state"] == "uploaded" and result["size"] > 0, "Asset not uploaded")
    digest = result.get("digest", "") or ""
    require(re.fullmatch(f"sha256:{HEX}", digest), f"Missing SHA-256 for {name}")
    if expected:
        require(digest == f"sha256:{expected}", f"Asset digest mismatch: {name}")
    return result


def download(package, release, name, directory):
    item = asset(release, name)
    run("gh", "release", "download", release["tag_name"], "--repo", f"oh-my-brew/{PRODUCTS[package][0]}", "--pattern", name, "--dir", str(directory))
    path = directory / name
    require(hashlib.sha256(path.read_bytes()).hexdigest() == item["digest"][7:], "Downloaded asset digest mismatch")
    return path


def bottle_ready(text, release, ver):
    block = one(BOTTLE, text)[0]
    root = f"https://github.com/oh-my-brew/omcli/releases/download/v{ver}"
    require(one(r'^    root_url "([^"]+)"$', block)[1] == root, "Waiting for current-version bottle writeback")
    rebuild = re.findall(r'^    rebuild ([0-9]+)$', block, re.M)
    require(len(rebuild) <= 1, "Ambiguous bottle rebuild")
    suffix = f".{rebuild[0]}" if rebuild and int(rebuild[0]) else ""
    sha = one(rf'^    sha256 cellar: :any_skip_relocation, arm64_tahoe: "({HEX})"$', block)[1]
    # Reject extra architectures, Ruby statements, or directives in the bottle block.
    expected = f'  bottle do\n    root_url "{root}"\n'
    if rebuild:
        expected += f'    rebuild {rebuild[0]}\n'
    expected += f'    sha256 cellar: :any_skip_relocation, arm64_tahoe: "{sha}"\n  end\n'
    require(block == expected, "Unexpected bottle directives")
    asset(release, f"omcli-{ver}.arm64_tahoe.bottle{suffix}.tar.gz", sha)


def safe_zip(path):
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            p = PurePosixPath(info.filename)
            require(not p.is_absolute() and '..' not in p.parts, "Unsafe ZIP path")
            if (info.external_attr >> 16) & 0o170000 == 0o120000:
                target = PurePosixPath(archive.read(info).decode())
                require(not target.is_absolute(), "Absolute ZIP symlink")
                depth = len(p.parent.parts)
                for part in target.parts:
                    depth += -1 if part == '..' else (0 if part == '.' else 1)
                    require(depth >= 1, "Escaping ZIP symlink")


def verify_app(package, ver, release, archive, directory):
    safe_zip(archive)
    unpacked = directory / "unpacked"
    run("ditto", "-x", "-k", str(archive), str(unpacked))
    name = "miniTools" if package == "minitools" else "RustDeskX"
    app = unpacked / f"{name}.app"
    plist = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    require(plist["CFBundleIdentifier"] == f"com.omzcj.{package}", "Wrong bundle ID")
    expected_version = ver if package == "minitools" else ver.rsplit('.', 1)[0]
    require(plist["CFBundleShortVersionString"] == expected_version, "Wrong application version")
    run("codesign", "--verify", "--deep", "--strict", str(app))
    identity = subprocess.check_output(["codesign", "-d", "--verbose=4", str(app)], stderr=subprocess.STDOUT, text=True)
    require(f"TeamIdentifier={TEAM}" in identity and "Authority=Developer ID Application:" in identity, "Wrong Developer ID identity")
    run("xcrun", "stapler", "validate", str(app))
    run("spctl", "--assess", "--type", "execute", str(app))
    executable = "MiniTools" if package == "minitools" else "RustDeskX"
    require(run("lipo", "-archs", str(app / 'Contents/MacOS' / executable)) == "arm64", "Wrong architecture")
    if package == "rustdeskx":
        require(plist["CFBundleVersion"].endswith("." + ver.split(".")[-1]), "Wrong RustDeskX revision")
    if package == "minitools":
        helper = app / "Contents/MacOS/MiniToolsPowerHelper"
        run("codesign", "--verify", "--strict", str(helper))
        helper_identity = subprocess.check_output(["codesign", "-d", "--verbose=4", str(helper)], stderr=subprocess.STDOUT, text=True)
        require(f"TeamIdentifier={TEAM}" in helper_identity and "Authority=Developer ID Application:" in helper_identity, "Wrong helper identity")
        require(run("lipo", "-archs", str(helper)) == "arm64", "Wrong helper architecture")
        require(plist["SUPublicEDKey"] == SPARKLE_KEY, "Unexpected Sparkle signing key")
        feed = download(package, release, "appcast.xml", directory)
        enclosures = ET.parse(feed).findall('.//enclosure')
        url = f"https://github.com/oh-my-brew/miniTools/releases/download/v{ver}/{archive.name}"
        matches = [e for e in enclosures if e.get('url') == url]
        require(len(matches) == 1 and int(matches[0].get('length', '0')) == archive.stat().st_size, "Wrong appcast enclosure")
        signature = matches[0].get('{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature', '')
        # Verify Sparkle's Ed25519 signature with Apple's system CryptoKit.
        run("swift", "scripts/verify_sparkle.swift", str(archive), SPARKLE_KEY, signature)


def verify_release(package, ver, text):
    release = latest(package)
    require(release['tag_name'] == f"v{ver}", "PR has been superseded by a newer stable Release")
    sha = one(rf'^  sha256 "({HEX})"$', text)[1]
    name = f"omcli-{ver}.tar.gz" if package == "omcli" else (f"miniTools-{ver}.zip" if package == "minitools" else f"RustDeskX-{ver}-arm64.zip")
    asset(release, name, sha)
    if package == "omcli":
        bottle_ready(text, release, ver)
    else:
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            archive = download(package, release, name, directory)
            checksum = download(package, release, name + '.sha256', directory)
            require(checksum.read_text().split() == [sha, name], "Release checksum file mismatch")
            verify_app(package, ver, release, archive, directory)


def gate(number, expected_head):
    pr = api(f"pulls/{number}")
    require(pr['head']['sha'] == expected_head, "PR head changed")
    try:
        selected = candidate(pr)
    except ValueError as error:
        print(f"Manual review: {error}")
        return False
    if selected is None:
        print("Manual review: not an eligible first-party automatic version PR")
        return False
    package, ver, text = selected
    verify_release(package, ver, text)
    fresh = api(f"pulls/{number}")
    require(fresh['head']['sha'] == expected_head and fresh['state'] == 'open', "PR changed during validation")
    print(f"Ready: {package} {ver}, PR #{number}, head {expected_head}")
    return True


def reconcile(report=False):
    pulls = api('pulls?state=open&per_page=100')
    require(len(pulls) < 100, "Too many open PRs; refusing incomplete inventory")
    for package, (_, path) in PRODUCTS.items():
        release = latest(package)
        target = release['tag_name'].removeprefix('v')
        current = version(content(path, 'main'), package)
        name = f'omcli-{target}.tar.gz' if package == 'omcli' else (f'miniTools-{target}.zip' if package == 'minitools' else f'RustDeskX-{target}-arm64.zip')
        asset(release, name)
        relevant = [p for p in pulls if p['head']['ref'].startswith(f'bump-{package}-')]
        print(f"{package}: tap={current}, stable={target}, PRs={[p['number'] for p in relevant]}")
        if current == target:
            continue
        matching = False
        for pr in relevant:
            selected = candidate(pr)
            require(selected is not None, f"Untrusted bump PR #{pr['number']}; manual resolution required")
            _, ver, _ = selected
            if ver == target:
                matching = True
                continue
            require(tuple(map(int, ver.split('.'))) < tuple(map(int, target.split('.'))), "PR version ahead of stable")
            require(not report, f"Stale PR #{pr['number']} remains")
            fresh = api(f"pulls/{pr['number']}")
            require(fresh['head']['sha'] == pr['head']['sha'] and fresh['state'] == 'open', "Stale PR changed")
            run('gh', 'pr', 'close', str(pr['number']), '--repo', REPO, '--comment', f"Superseded by stable release {release['html_url']}. The scheduled Autobump will create the current version PR; history is retained.")
        if report:
            require(matching, f"No PR for latest {package} {target}")


def needs_update(pr):
    # mergeable_state may be "blocked" while CI runs even if main advanced.
    comparison = api(f"compare/{pr['base']['sha']}...{pr['head']['sha']}")
    return comparison['behind_by'] > 0


def sync():
    pulls = api('pulls?state=open&per_page=100')
    require(len(pulls) < 100, "Too many open PRs")
    for pr in pulls:
        try:
            selected = candidate(pr)
        except ValueError as error:
            print(f"Manual review PR #{pr['number']}: {error}")
            continue
        if selected is None:
            continue
        package, ver, _ = selected
        if latest(package)['tag_name'] != f'v{ver}':
            continue
        fresh = api(f"pulls/{pr['number']}")
        require(fresh['head']['sha'] == pr['head']['sha'], "PR changed during sync")
        if needs_update(fresh):
            api(f"pulls/{pr['number']}/update-branch", 'PUT', {'expected_head_sha': fresh['head']['sha']})
            print(f"Updated PR #{pr['number']} with current main; waiting for new-head CI")
        else:
            run('gh', 'workflow', 'run', 'release-ready.yml', '--repo', REPO, '--ref', 'main', '-f', f"pr={pr['number']}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['prepare', 'report', 'gate', 'merge', 'sync'])
    parser.add_argument('--pr', type=int)
    parser.add_argument('--head')
    args = parser.parse_args()
    if args.mode in ('prepare', 'report'):
        reconcile(args.mode == 'report')
    elif args.mode == 'sync':
        sync()
    elif args.mode == 'gate':
        eligible = gate(args.pr, args.head)
        if os.getenv('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
                output.write(f"eligible={str(eligible).lower()}\n")
    else:
        # Repeat structural/current-release checks at the mutation boundary.
        pr = api(f'pulls/{args.pr}')
        require(pr['head']['sha'] == args.head, "PR head changed before auto-merge")
        selected = candidate(pr)
        require(selected is not None, "PR no longer eligible")
        require(latest(selected[0])['tag_name'] == f'v{selected[1]}', "Stable Release changed")
        if needs_update(pr):
            api(f'pulls/{args.pr}/update-branch', 'PUT', {'expected_head_sha': args.head})
            print('Branch updated; waiting for new-head checks')
            return
        run('gh', 'pr', 'merge', str(args.pr), '--repo', REPO, '--auto', '--squash', '--match-head-commit', args.head)


if __name__ == '__main__':
    main()
