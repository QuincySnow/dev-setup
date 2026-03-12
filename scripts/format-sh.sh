#!/usr/bin/env bash
# =============================================================================
# Format and lint all shell scripts in the project
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Shell Format & Lint ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Find all .sh files, excluding this script and hidden directories
mapfile -t SH_FILES < <(find "$PROJECT_ROOT" -name "*.sh" -type f ! -path "*/.*" ! -name "$(basename "$0")" | sort)

if [[ ${#SH_FILES[@]} -eq 0 ]]; then
	echo "No shell scripts found."
	exit 0
fi

echo "Found ${#SH_FILES[@]} shell script(s):"
for f in "${SH_FILES[@]}"; do
	echo "  - $f"
done
echo ""

# Format with shfmt
echo "=== Formatting with shfmt ==="
for f in "${SH_FILES[@]}"; do
	if command -v shfmt &>/dev/null; then
		shfmt -i 2 -w -s "$f"
		echo "Formatted: $f"
	else
		echo "skipped (shfmt not installed): $f"
	fi
done
echo ""

# Lint with shellcheck
echo "=== Linting with ShellCheck ==="
for f in "${SH_FILES[@]}"; do
	if command -v shellcheck &>/dev/null; then
		if shellcheck -S error "$f"; then
			echo "OK: $f"
		else
			echo "ERROR: $f has issues"
		fi
	else
		echo "skipped (shellcheck not installed): $f"
	fi
done
echo ""

echo "=== Done ==="
