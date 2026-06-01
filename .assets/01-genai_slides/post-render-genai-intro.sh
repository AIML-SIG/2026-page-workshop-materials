#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

deck_dir="$repo_root/01_genai_coding_assistants/slides"
asset_dir="$repo_root/.assets/01-genai_slides"
support_name="genai_intro_files"
html="$deck_dir/genai_intro.html"
support_src="$deck_dir/$support_name"
support_dst="$asset_dir/$support_name"

if [[ ! -f "$html" ]]; then
  exit 0
fi

mkdir -p "$asset_dir"

if [[ -d "$support_src" ]]; then
  rm -rf "$support_dst"
  mv "$support_src" "$support_dst"
fi

# Keep path rewrite idempotent across repeated renders.
sed -i 's|"../../\.assets/01-genai_slides/genai_intro_files/|"genai_intro_files/|g' "$html"
sed -i "s|'../../\\.assets/01-genai_slides/genai_intro_files/|'genai_intro_files/|g" "$html"
sed -i 's|"genai_intro_files/|"../../.assets/01-genai_slides/genai_intro_files/|g' "$html"
sed -i "s|'genai_intro_files/|'../../.assets/01-genai_slides/genai_intro_files/|g" "$html"
