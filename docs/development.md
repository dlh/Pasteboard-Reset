# Development

Build the app from the command line:

```sh
make release
```

The app version is read from `VERSION`, and the build number defaults to the
number of commits on the current branch. You can override both values:

```sh
make release VERSION=1.2.3 BUILD_NUMBER=42
```

If you add or remove an `NSLocalizedString` call, keep
`Resources/en.lproj/Localizable.strings` in sync and verify it with:

```sh
make check-strings
```

Preview the next semantic-release version and release notes with:

```sh
npm ci --prefix .release
make release-dry-run
```

Use the Conventional Commits format for commit messages so semantic-release can
determine the next version and generate release notes correctly.

Local builds are ad-hoc signed by default. To sign with a Developer ID
certificate, pass the signing identity:

```sh
make release SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

For distribution outside your own machine, create a notarytool keychain profile,
then build, archive, notarize, and staple the app:

```sh
make staple \
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  NOTARY_PROFILE="PasteboardResetNotary"
```
