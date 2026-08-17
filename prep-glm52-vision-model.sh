#!/usr/bin/env bash

# Adapted from:
# https://github.com/ciprianveg/gb10-glm-5.2/blob/c3980ec81efacac619237a8bcaf110a8d2890901/v18-vision/README-v18.1.md

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

HF_HOME_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
HF_CACHE="${HF_HUB_CACHE:-$HF_HOME_DIR/hub}"

hf download \
  --revision 1d3bcfe5ec549ecd000fd80b37f191183842e983 \
  QuantTrio/GLM-5.2-Int4-Int8Mix

hf download \
  --revision f6eab6117386a0c69152fdf272dc65bfd0254f9f \
  baseten/GLM-5.2-Vision-NVFP4 \
  mm_projector.safetensors \
  vision_tower.safetensors \
  config.json \
  preprocessor_config.json \
  chat_template.jinja \
  model.safetensors.index.json \
  kimi_k25_processor.py \
  kimi_k25_vision_processing.py \
  media_utils.py \
  configuration_glm5v.py

GB10_URL="https://github.com/ciprianveg/gb10-glm-5.2.git"
GB10_DIR="$SCRIPT_DIR/gb10-glm-5.2"
GB10_COMMIT="c3980ec81efacac619237a8bcaf110a8d2890901"

if [[ -d "$GB10_DIR/.git" ]]; then
    echo "Repository already present: $GB10_DIR"
elif [[ -e "$GB10_DIR" ]]; then
    echo "Error: $GB10_DIR exists but is not a Git repository." >&2
    exit 1
else
    git clone "$GB10_URL" "$GB10_DIR"
fi

if ! git -C "$GB10_DIR" cat-file -e \
    "${GB10_COMMIT}^{commit}" 2>/dev/null; then
    git -C "$GB10_DIR" fetch origin "$GB10_COMMIT"
fi

git -C "$GB10_DIR" checkout --detach "$GB10_COMMIT"

TEXT_DIR="$HF_CACHE/models--QuantTrio--GLM-5.2-Int4-Int8Mix/snapshots/1d3bcfe5ec549ecd000fd80b37f191183842e983"
VISION_DIR="$HF_CACHE/models--baseten--GLM-5.2-Vision-NVFP4/snapshots/f6eab6117386a0c69152fdf272dc65bfd0254f9f"
OUTPUT_DIR="$HF_HOME_DIR/glm52-quanttrio-vision"

python3 "$GB10_DIR/v18-vision/scripts/assemble_quanttrio_glm5v.py" \
  --text-dir "$TEXT_DIR" \
  --vision-dir "$VISION_DIR" \
  --output-dir "$OUTPUT_DIR"

MODEL="$OUTPUT_DIR"

find "$MODEL" -type l -print0 |
while IFS= read -r -d '' link; do
    target="$(readlink -f -- "$link")"

    if [[ ! -f "$target" ]]; then
        echo "Broken or non-file symlink: $link -> $(readlink "$link")" >&2
        exit 1
    fi

    tmp="${link}.materializing.$$"

    ln -- "$target" "$tmp"
    mv -fT -- "$tmp" "$link"
done

echo "Composite vision model ready: $OUTPUT_DIR"