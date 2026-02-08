#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${WORKDIR:-/tmp/dotfiles-workflow-check}"
mkdir -p "$WORKDIR"

# Ensure GH auth (use rbw token if available)
if [[ -z "${GH_TOKEN:-}" ]] && command -v rbw >/dev/null 2>&1; then
  export GH_TOKEN=$(rbw get github_token 2>/dev/null || true)
fi

# Get viewer login
USER_LOGIN=$(gh api user --jq .login)

if [[ -z "$USER_LOGIN" || "$USER_LOGIN" == "null" ]]; then
  echo "AUTH_FAILED"
  exit 1
fi

# Collect orgs
ORGS=$(gh api user/orgs --jq '.[].login' || true)

# Build repo list (user + orgs)
REPOS=()

# User repos (limit to repos owned by user)
while IFS= read -r repo; do
  [[ -n "$repo" ]] && REPOS+=("$repo")
done < <(gh repo list "$USER_LOGIN" --limit 200 --json name,nameWithOwner --jq '.[] | select(.name | test("dotfiles"; "i")) | .nameWithOwner')

# Org repos
for org in $ORGS; do
  while IFS= read -r repo; do
    [[ -n "$repo" ]] && REPOS+=("$repo")
  done < <(gh repo list "$org" --limit 200 --json name,nameWithOwner --jq '.[] | select(.name | test("dotfiles"; "i")) | .nameWithOwner')
done

# De-duplicate
IFS=$'\n' REPOS=($(printf "%s\n" "${REPOS[@]}" | awk '!seen[$0]++'))
unset IFS

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "NO_REPOS"
  exit 0
fi

# Helper: best-effort workflow fixes
apply_best_effort_fixes() {
  local repo_dir="$1"
  local changed=0

  shopt -s nullglob
  local files=("$repo_dir"/.github/workflows/*.yml "$repo_dir"/.github/workflows/*.yaml)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    return 1
  fi

  # Bump common GitHub Action versions
  for f in "${files[@]}"; do
    perl -pi -e 's/actions\/checkout\@v[23]/actions\/checkout\@v4/g' "$f"
    perl -pi -e 's/actions\/setup-node\@v[23]/actions\/setup-node\@v4/g' "$f"
    perl -pi -e 's/actions\/setup-python\@v[234]/actions\/setup-python\@v5/g' "$f"
    perl -pi -e 's/actions\/setup-go\@v[234]/actions\/setup-go\@v5/g' "$f"
    perl -pi -e 's/actions\/cache\@v[23]/actions\/cache\@v4/g' "$f"
  done

  if ! git -C "$repo_dir" diff --quiet; then
    changed=1
  fi

  if [[ $changed -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

for repo in "${REPOS[@]}"; do
  # Find latest scheduled run
  RUN_JSON=$(gh run list --repo "$repo" --event schedule --limit 1 --json databaseId,conclusion,createdAt,updatedAt,workflowName,displayTitle --jq '.[0]')

  if [[ -z "$RUN_JSON" || "$RUN_JSON" == "null" ]]; then
    echo "NO_SCHEDULED_RUN $repo"
    continue
  fi

  RUN_ID=$(printf '%s' "$RUN_JSON" | jq -r '.databaseId')
  CONCLUSION=$(printf '%s' "$RUN_JSON" | jq -r '.conclusion')

  if [[ "$CONCLUSION" != "failure" && "$CONCLUSION" != "timed_out" && "$CONCLUSION" != "cancelled" ]]; then
    echo "OK $repo"
    continue
  fi

  # Clone repo
  REPO_DIR="$WORKDIR/$(echo "$repo" | tr '/' '__')"
  rm -rf "$REPO_DIR"
  gh repo clone "$repo" "$REPO_DIR" >/dev/null

  # Create branch
  BRANCH="bot/fix-workflow-$(date +%Y%m%d)"
  git -C "$REPO_DIR" checkout -b "$BRANCH" >/dev/null

  # Attempt best-effort fixes
  if apply_best_effort_fixes "$REPO_DIR"; then
    git -C "$REPO_DIR" add .
    git -C "$REPO_DIR" commit -m "chore: update GitHub Actions versions" >/dev/null
    git -C "$REPO_DIR" push -u origin "$BRANCH" >/dev/null

    PR_URL=$(gh pr create --repo "$repo" --head "$BRANCH" --title "chore: fix workflow failures" --body "Best-effort update of common GitHub Actions versions based on recent scheduled workflow failure. Please review." --json url --jq .url)
    echo "PR_CREATED $repo $PR_URL"
  else
    echo "CANNOT_FIX $repo"
  fi

done
