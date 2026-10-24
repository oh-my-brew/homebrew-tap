import Foundation
import CryptoKit

let args = CommandLine.arguments
let archive = try Data(contentsOf: URL(fileURLWithPath: args[1]))
guard let rawKey = Data(base64Encoded: args[2]),
      let signature = Data(base64Encoded: args[3]) else { fatalError("Invalid Ed25519 input") }
let key = try Curve25519.Signing.PublicKey(rawRepresentation: rawKey)
guard key.isValidSignature(signature, for: archive) else { fatalError("Invalid Sparkle signature") }
print("Sparkle archive signature verified")
