#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bin/sync_github_secrets_from_1password.sh [--dry-run] [--repo owner/repo] op://VAULT/ITEM

Reads release signing secrets from a 1Password item and stores them as GitHub
Actions repository secrets. Fields in the 1Password item must use the same names
as the GitHub secrets.

Required fields:
  APPLE_APP_SPECIFIC_PASSWORD
  APPLE_CERTIFICATE_P12_BASE64
  APPLE_CERTIFICATE_PASSWORD
  APPLE_ID
  APPLE_SIGN_IDENTITY
  APPLE_TEAM_ID
  KEYCHAIN_PASSWORD

Examples:
  bin/sync_github_secrets_from_1password.sh --dry-run "op://Private/GitHub Pasteboard Reset Secrets"
  bin/sync_github_secrets_from_1password.sh "op://Private/GitHub Pasteboard Reset Secrets"
  bin/sync_github_secrets_from_1password.sh --repo dlh/pasteboard-reset "op://Private/GitHub Pasteboard Reset Secrets"
EOF
}

readonly SECRETS=(
  APPLE_APP_SPECIFIC_PASSWORD
  APPLE_CERTIFICATE_P12_BASE64
  APPLE_CERTIFICATE_PASSWORD
  APPLE_ID
  APPLE_SIGN_IDENTITY
  APPLE_TEAM_ID
  KEYCHAIN_PASSWORD
)

die() {
  echo "$1" >&2
  exit 1
}

parse_args() {
  repo_args=()
  item_ref=
  dry_run=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --repo)
        if [ "$#" -lt 2 ]; then
          die "Missing value for --repo."
        fi
        repo_args=(--repo "$2")
        shift 2
        ;;
      --repo=*)
        repo_args=(--repo "${1#--repo=}")
        shift
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        if [ -n "${item_ref}" ]; then
          echo "Only one 1Password item reference may be provided." >&2
          usage >&2
          exit 1
        fi
        item_ref="${1%/}"
        shift
        ;;
    esac
  done

  if [ -z "${item_ref}" ]; then
    usage >&2
    exit 1
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "$2"
  fi
}

check_dependencies() {
  require_command op "1Password CLI is required: op"

  if [ "${dry_run}" -eq 0 ]; then
    require_command gh "GitHub CLI is required: gh"
  fi
}

read_secret() {
  op read "${item_ref}/$1"
}

dry_run_secret() {
  local secret=$1

  read_secret "${secret}" >/dev/null
  echo "Would set ${secret}."
}

sync_secret() {
  local secret=$1

  echo "Setting ${secret}..."
  read_secret "${secret}" | gh secret set "${secret}" "${repo_args[@]}"
}

sync_secrets() {
  local secret

  for secret in "${SECRETS[@]}"; do
    if [ "${dry_run}" -eq 1 ]; then
      dry_run_secret "${secret}"
    else
      sync_secret "${secret}"
    fi
  done
}

print_summary() {
  if [ "${dry_run}" -eq 1 ]; then
    echo "Dry run succeeded. No GitHub secrets were changed."
  else
    echo "GitHub release secrets are up to date."
  fi
}

main() {
  parse_args "$@"
  check_dependencies
  sync_secrets
  print_summary
}

main "$@"
