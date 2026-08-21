module.exports = {
  branches: ["master"],
  repositoryUrl: "git@github.com:dlh/Pasteboard-Reset.git",
  tagFormat: "v${version}",
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
        changelogTitle: "Pasteboard Reset Changelog\n=========================",
      },
    ],
    [
      "@semantic-release/exec",
      {
        prepareCmd:
          "make semantic-release-prepare VERSION='${nextRelease.version}' BUILD_NUMBER=\"$GITHUB_RUN_NUMBER\" SIGN_IDENTITY=\"$APPLE_SIGN_IDENTITY\" NOTARY_PROFILE=\"$NOTARY_PROFILE\"",
      },
    ],
    [
      "@semantic-release/git",
      {
        assets: ["VERSION", "CHANGELOG.md"],
        message: "chore(release): ${nextRelease.version}\n\nskip-checks: true",
      },
    ],
    [
      "@semantic-release/github",
      {
        assets: [
          {
            path: "build/Pasteboard Reset-*.zip",
            label: "Pasteboard Reset ${nextRelease.version}",
          },
        ],
        failCommentCondition: false,
        successCommentCondition: false,
      },
    ],
  ],
};
