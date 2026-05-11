# Petty Followers Workflow Debug Guide

Use this as a copy-paste sanity check for your actual stats repo.

## 1) Secret Mapping (Most Important)

- `FOLLOWERS_GIST_ID` = only the gist ID string
- `GIST` (or `GIST_TOKEN`) = token with `gist` scope
- `STATS_TOKEN` = token used for follower/star actions

Do **not** put `.json` in `FOLLOWERS_GIST_ID`.

## 2) Gist File Naming

Inside the gist, the file should be exactly:

- `followers-gist.json`

The filename is separate from the gist ID secret.

## 3) Pagination-Safe Follower Fetch (REST)

```bash
gh api "/user/followers?per_page=100" --paginate --jq '.[].login'
```

If this works in Actions, pagination is good.

## 4) Minimal Update Step for Gist

```bash
# Build JSON array from current_followers.txt
jq -R -s 'split("\n") | map(select(length>0))' < current_followers.txt > followers-gist.json

# Patch gist file content
gh api -X PATCH "/gists/$GIST_ID" \
  -f "files[followers-gist.json][content]=$(cat followers-gist.json)"
```

Where env should include:

```yaml
env:
  GIST_ID: ${{ secrets.FOLLOWERS_GIST_ID }}
  GH_TOKEN: ${{ secrets.GIST }}
```

## 5) Common Failure Causes

- Secret name mismatch in workflow vs repo settings
- Using gist URL or filename in `FOLLOWERS_GIST_ID` instead of raw ID
- Token scope missing (`gist` for gist updates, follow/star scopes for STATS token)
- Typo/case mismatch in `followers-gist.json`
- GraphQL pagination query missing `endCursor` pattern

## 6) Fast Triage in Failed Action

Print these before API calls:

```bash
echo "GIST_ID length: ${#GIST_ID}"
echo "Has STATS_TOKEN: $([ -n "$STATS_TOKEN" ] && echo yes || echo no)"
echo "Has GIST token: $([ -n "$GH_TOKEN" ] && echo yes || echo no)"
```

Then test:

```bash
gh api "/gists/$GIST_ID" --jq '.id,.files | keys'
```

If this fails, it is ID/token wiring, not pagination.

## 7) One-Line Mental Model

- Gist ID selects the container.
- `followers-gist.json` selects the file in that container.
- Token grants permission to read/write.
