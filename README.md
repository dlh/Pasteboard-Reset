Pasteboard Reset
================

A macOS menu bar application to clear the pasteboard.

Building
--------

Build the app from the command line:

```sh
make release
```

The app version is read from `VERSION`, and the build number defaults to the
number of commits on the current branch. You can override both values:

```sh
make release VERSION=1.2.3 BUILD_NUMBER=42
```

By default, the app is ad-hoc signed for local use. To sign with a Developer ID
certificate later, pass the signing identity:

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

Builds are not Developer ID signed by default. If macOS blocks a downloaded
build because it is quarantined, remove the quarantine attribute after you trust
the app:

```sh
xattr -dr com.apple.quarantine "Pasteboard Reset.app"
```

License
-------

This project is released under the MIT license. See LICENSE.txt for more
information.

Pasteboard Reset's icons are derived from [Elusive Icons](http://elusiveicons.com).

Releasing
---------

Releases are published by GitHub Actions when a semantic version tag is pushed:

```sh
printf '1.2.3\n' > VERSION
git add VERSION
git commit -m "chore: release 1.2.3"
make release-tag
git push origin master v1.2.3
```

The workflow builds `Pasteboard Reset-1.2.3.zip`, creates the GitHub release,
and uploads the archive. It can also be run manually from the Actions tab with
a version input.
