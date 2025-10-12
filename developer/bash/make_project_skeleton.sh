#!/usr/bin/env bash

# this has never been run, but is the general idea ...  ROOT_DIR needs to be changed

set -e

ROOT_DIR="${1:-Harmony}"
echo "Creating Harmony project skeleton in: $ROOT_DIR"

# Create top-level structure
mkdir -p "$ROOT_DIR"/{developer,release,tester,tmp,tool_shared/{bespoke🖉,customized,document🖉,third_party}}

# Create env_<role> scripts as placeholders
for role in developer tester toolsmith; do
  touch "$ROOT_DIR/env_$role"
done

# Create LICENSE and README.md placeholders
touch "$ROOT_DIR/LICENSE"
touch "$ROOT_DIR/README.md"

# Create git_holder in release/ and tester/
touch "$ROOT_DIR/release/git_holder"
touch "$ROOT_DIR/tester/git_holder"

# Create .gitignore in tmp/ and third_party/
cat > "$ROOT_DIR/tmp/.gitignore" <<EOF
# Ignore all files
*
!.gitignore
EOF

cat > "$ROOT_DIR/tool_shared/third_party/.gitignore" <<EOF
# Ignore all files
*
!.gitignore
EOF

# Add placeholder files in document🖉 and bespoke🖉
touch "$ROOT_DIR/tool_shared/bespoke🖉/env"
touch "$ROOT_DIR/tool_shared/bespoke🖉/version"
touch "$ROOT_DIR/tool_shared/document🖉/README.org"

# Feedback
echo "✔ Project skeleton created."
echo "   Remember to edit env_<role> scripts and LICENSE as needed."
