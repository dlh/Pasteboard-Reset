Pasteboard Reset
================

A macOS menu bar application to clear the pasteboard.

Building
--------

Build the app from the command line:

```sh
make release
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

License
-------

This project is released under the MIT license. See LICENSE.txt for more
information.

Pasteboard Reset's icons are derived from [Elusive Icons](http://elusiveicons.com).
