# GitHub Releases

GitHub Actions runs semantic-release after commits land on `master`:

```sh
git push origin master
```

semantic-release chooses the next version from commit subjects using
Conventional Commit rules. Breaking changes become a major release, `feat:`
commits become a minor release, and `fix:` or `perf:` commits become a patch
release.

Preview the next release locally:

```sh
npm ci --prefix .release
make release-dry-run
```

When a release is needed, semantic-release updates `VERSION`, prepends
`CHANGELOG.md`, commits those files with `skip-checks: true`, creates the `vX.Y.Z`
tag, builds the signed and notarized archive, and publishes the GitHub Release
with the generated release notes.

Regenerate the historical changelog entries from existing tags and commit
history with:

```sh
npm --prefix .release run changelog:backfill
```

## Signing And Notarization

The workflow builds, signs, notarizes, staples, and uploads
`Pasteboard Reset-1.2.3.zip`.

Configure these repository secrets:

```text
APPLE_APP_SPECIFIC_PASSWORD
APPLE_CERTIFICATE_P12_BASE64
APPLE_CERTIFICATE_PASSWORD
APPLE_ID
APPLE_SIGN_IDENTITY
APPLE_TEAM_ID
KEYCHAIN_PASSWORD
```

If these values are stored in a 1Password item with matching field names, sync
them to the current GitHub repository. First verify that all fields can be read:

```sh
bin/sync_github_secrets_from_1password.sh \
  --dry-run \
  "op://Private/Pasteboard Reset GitHub Secrets"
```

Then sync them:

```sh
bin/sync_github_secrets_from_1password.sh "op://Private/Pasteboard Reset GitHub Secrets"
```

To target a specific repository instead of the current checkout:

```sh
bin/sync_github_secrets_from_1password.sh \
  --repo owner/repo \
  "op://Private/Pasteboard Reset GitHub Secrets"
```

Set `APPLE_SIGN_IDENTITY` to the full Developer ID Application identity, such as
`Developer ID Application: Your Name (TEAMID)`.

Set `APPLE_TEAM_ID` to the Apple Developer team ID, and set `APPLE_ID` to the
Apple ID used for notarization.

Use an Apple app-specific password for `APPLE_APP_SPECIFIC_PASSWORD`.

## Certificate Export

Export the Developer ID Application certificate from Keychain Access as a
password-protected `.p12`. The certificate must include its private key.

Use the `.p12` export password for `APPLE_CERTIFICATE_PASSWORD`.

Base64-encode the `.p12` for `APPLE_CERTIFICATE_P12_BASE64`:

```sh
base64 -i DeveloperID.p12 | pbcopy
```

Set `KEYCHAIN_PASSWORD` to any strong password. The workflow uses it only for a
temporary keychain on the GitHub Actions runner.
