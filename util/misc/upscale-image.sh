#!/bin/bash
#
# upscale-image.sh - AI-powered image upscaling using Real-ESRGAN on GPU
#
# Usage:
#   upscale-image.sh <input> <output> [options]
#
# Examples:
#   upscale-image.sh photo.jpg photo-4x.png
#   upscale-image.sh photo.jpg photo-4x.webp --scale 2
#   upscale-image.sh photo.jpg upscaled/ --format webp --quality 95
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
SCALE=4
FORMAT=""
QUALITY=95
FORCE=false
MODEL="RealESRGAN_x4plus"
MODEL_PATH="/tmp/RealESRGAN_x4plus.pth"
MODEL_URL="https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"

usage() {
    echo -e "${BLUE}upscale-image.sh${NC} - AI-powered image upscaling using Real-ESRGAN (GPU)"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  upscale-image.sh <input> <output> [options]"
    echo ""
    echo -e "${YELLOW}Arguments:${NC}"
    echo "  input     Input image file (jpg, png, webp, etc.)"
    echo "  output    Output file path OR directory (format inferred from extension)"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -s, --scale <n>      Upscale factor: 2, 3, or 4 (default: 4)"
    echo "  -f, --format <fmt>   Output format: png, jpg, webp (default: from output path)"
    echo "  -q, --quality <n>    Quality 1-100 for jpg/webp (default: 95)"
    echo "  -y, --force          Skip confirmation for large images"
    echo "  -h, --help           Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  upscale-image.sh photo.jpg photo-upscaled.png"
    echo "  upscale-image.sh photo.jpg photo-upscaled.webp --scale 2"
    echo "  upscale-image.sh photo.jpg ./output/ --format webp --quality 90"
    echo ""
    echo -e "${YELLOW}Requirements:${NC}"
    echo "  - Python 3 with torch, realesrgan, basicsr, opencv-python"
    echo "  - NVIDIA GPU with CUDA support (falls back to CPU if unavailable)"
    exit 0
}

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Parse arguments
INPUT=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -s|--scale)
            SCALE="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -y|--force)
            FORCE=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            elif [[ -z "$OUTPUT" ]]; then
                OUTPUT="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Validate arguments
[[ -z "$INPUT" ]] && error "Input file required. Use --help for usage."
[[ -z "$OUTPUT" ]] && error "Output path required. Use --help for usage."
[[ ! -f "$INPUT" ]] && error "Input file not found: $INPUT"
[[ "$SCALE" =~ ^[234]$ ]] || error "Scale must be 2, 3, or 4"

# Determine output path and format
if [[ -d "$OUTPUT" ]]; then
    # Output is a directory, construct filename
    BASENAME=$(basename "$INPUT")
    NAME="${BASENAME%.*}"
    if [[ -z "$FORMAT" ]]; then
        FORMAT="png"
    fi
    OUTPUT="${OUTPUT%/}/${NAME}-${SCALE}x.${FORMAT}"
elif [[ "$OUTPUT" == */ ]]; then
    # Trailing slash but doesn't exist yet
    mkdir -p "$OUTPUT"
    BASENAME=$(basename "$INPUT")
    NAME="${BASENAME%.*}"
    if [[ -z "$FORMAT" ]]; then
        FORMAT="png"
    fi
    OUTPUT="${OUTPUT%/}/${NAME}-${SCALE}x.${FORMAT}"
else
    # Output is a file path
    if [[ -z "$FORMAT" ]]; then
        FORMAT="${OUTPUT##*.}"
    fi
fi

# Validate format
FORMAT=$(echo "$FORMAT" | tr '[:upper:]' '[:lower:]')
case $FORMAT in
    png|jpg|jpeg|webp) ;;
    *) error "Unsupported format: $FORMAT. Use png, jpg, or webp" ;;
esac

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# Check input image dimensions and warn if large
INPUT_DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$INPUT" 2>/dev/null)
INPUT_WIDTH=$(echo "$INPUT_DIMS" | cut -d',' -f1)
INPUT_HEIGHT=$(echo "$INPUT_DIMS" | cut -d',' -f2)

if [[ -n "$INPUT_WIDTH" && -n "$INPUT_HEIGHT" ]]; then
    OUTPUT_WIDTH=$((INPUT_WIDTH * SCALE))
    OUTPUT_HEIGHT=$((INPUT_HEIGHT * SCALE))
    OUTPUT_MEGAPIXELS=$(( (OUTPUT_WIDTH * OUTPUT_HEIGHT) / 1000000 ))

    # Warn if output would exceed 20 megapixels
    if [[ $OUTPUT_MEGAPIXELS -gt 20 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARNING: Large output image detected${NC}"
        echo ""
        echo -e "  Input:    ${INPUT_WIDTH}x${INPUT_HEIGHT}"
        echo -e "  Output:   ${OUTPUT_WIDTH}x${OUTPUT_HEIGHT} (${OUTPUT_MEGAPIXELS} megapixels)"
        echo ""
        echo -e "  This may ${RED}exhaust GPU memory${NC} (even a 24GB RTX 4090 can struggle with 60+ MP)"
        echo -e "  Consider using a smaller scale factor or downscaling the input first."
        echo ""

        if [[ "$FORCE" != "true" ]]; then
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 0
            fi
        else
            echo -e "  ${BLUE}(--force specified, continuing...)${NC}"
        fi
        echo ""
    fi
fi

# Temporary files
TEMP_DIR=$(mktemp -d)
TEMP_OUTPUT="$TEMP_DIR/upscaled.png"
trap "rm -rf $TEMP_DIR" EXIT

info "Input: $INPUT"
info "Output: $OUTPUT"
info "Scale: ${SCALE}x"
info "Format: $FORMAT (quality: $QUALITY)"

# Download model if needed
if [[ ! -f "$MODEL_PATH" ]]; then
    info "Downloading Real-ESRGAN model..."
    wget -q --show-progress -O "$MODEL_PATH" "$MODEL_URL" || \
        error "Failed to download model"
fi

# Run upscaling
info "Upscaling with Real-ESRGAN on GPU..."

python3 << EOF
import sys

# Patch for torchvision compatibility
class MockModule:
    @staticmethod
    def rgb_to_grayscale(*args, **kwargs):
        from torchvision.transforms.functional import rgb_to_grayscale
        return rgb_to_grayscale(*args, **kwargs)
sys.modules['torchvision.transforms.functional_tensor'] = MockModule()

import torch
import cv2
import time

# Check GPU
device = 'cuda' if torch.cuda.is_available() else 'cpu'
if device == 'cuda':
    print(f"Using GPU: {torch.cuda.get_device_name(0)}")
else:
    print("WARNING: CUDA not available, using CPU (this will be slow)")

from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer

# Select model based on scale
scale = $SCALE
if scale == 2:
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=2)
    # For 2x, we use 4x model and let outscale handle it
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=4)
else:
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=4)

upsampler = RealESRGANer(
    scale=4,
    model_path='$MODEL_PATH',
    model=model,
    tile=0 if device == 'cuda' else 256,  # Tile for CPU to manage memory
    tile_pad=10,
    pre_pad=0,
    half=True if device == 'cuda' else False,
    device=device
)

# Load and process
img = cv2.imread('$INPUT', cv2.IMREAD_UNCHANGED)
if img is None:
    print("ERROR: Failed to load image")
    sys.exit(1)

h, w = img.shape[:2]
print(f"Input: {w}x{h}")

start = time.time()
output, _ = upsampler.enhance(img, outscale=$SCALE)
elapsed = time.time() - start

out_h, out_w = output.shape[:2]
print(f"Output: {out_w}x{out_h}")
print(f"Time: {elapsed:.2f}s")

cv2.imwrite('$TEMP_OUTPUT', output)
print("Upscaling complete")
EOF

if [[ $? -ne 0 ]]; then
    error "Upscaling failed"
fi

# Convert to desired format
info "Converting to $FORMAT..."

case $FORMAT in
    png)
        cp "$TEMP_OUTPUT" "$OUTPUT"
        ;;
    jpg|jpeg)
        ffmpeg -y -i "$TEMP_OUTPUT" -q:v $((100 - QUALITY + 2)) "$OUTPUT" 2>/dev/null || \
            convert "$TEMP_OUTPUT" -quality "$QUALITY" "$OUTPUT"
        ;;
    webp)
        ffmpeg -y -i "$TEMP_OUTPUT" -c:v libwebp -quality "$QUALITY" -preset photo "$OUTPUT" 2>/dev/null || \
            convert "$TEMP_OUTPUT" -quality "$QUALITY" "$OUTPUT"
        ;;
esac

# Report results
FINAL_SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
FINAL_DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT" 2>/dev/null || echo "unknown")

success "Done!"
echo ""
echo -e "  ${GREEN}Output:${NC} $OUTPUT"
echo -e "  ${GREEN}Size:${NC}   $FINAL_SIZE"
echo -e "  ${GREEN}Dims:${NC}   $FINAL_DIMS"
