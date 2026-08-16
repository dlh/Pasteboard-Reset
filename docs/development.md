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

Preview the next semantic-release version and release notes with:

```sh
npm ci --prefix .release
make release-dry-run
```

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
