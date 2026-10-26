/// Ed25519 public verification key for offline license activation.
///
/// Only the PUBLIC key lives in the app. The matching private seed is kept
/// by the operator in `tools/license_issuer/keys/` (gitignored) and is used
/// exclusively by the local issuer CLI to sign activation codes.
///
/// To rotate the keypair:
/// 1. `dart run bin/generate_keypair.dart --force` inside `tools/license_issuer`.
/// 2. Update this constant with the newly printed public key.
/// 3. Ship a new app release. Codes signed with the old key are then rejected.
const String kLicensePublicKeyBase64 =
    '4MHvPd1JjJT8YWN1GvnYBFKB8ZkLKxya4wwTPGyZeDc=';
