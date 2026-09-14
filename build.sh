#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

echo "Seawolf / Missile ROM build"
echo "Input: src/Seawolf.asm"
echo "System ROM: roms/original/astro.bin"

if [[ ! -f roms/original/astro.bin ]]; then
    echo
    echo "ERROR: Missing required Astrocade system ROM: roms/original/astro.bin"
    exit 1
fi

echo
echo "[1/3] Assemble the 2 KB cartridge image"
mkdir -p src/zout roms
echo "+ tools/zmac -i -m -o zout/seawolf.bin -x zout/seawolf.lst Seawolf.asm"
(
    cd src
    ../tools/zmac -i -m -o zout/seawolf.bin -x zout/seawolf.lst Seawolf.asm
)
echo "Created: src/zout/seawolf.bin"
echo "Created: src/zout/seawolf.lst"

echo
echo "[2/3] Verify cartridge and system ROM SHA-1"
hash_failed=0

verify_sha1() {
    local rom_file="$1"
    local expected_sha1="$2"
    local actual_sha1

    actual_sha1="$(sha1sum "$rom_file" | awk '{print $1}')"
    printf '%s  %s\n' "$actual_sha1" "$rom_file"

    if [[ "$actual_sha1" != "$expected_sha1" ]]; then
        echo "WARNING: SHA-1 mismatch for $rom_file"
        echo "  Expected: $expected_sha1"
        echo "  Actual:   $actual_sha1"
        hash_failed=1
    fi
}

verify_sha1 src/zout/seawolf.bin 4c2ca46ab5a00dc2eb252ee900b2760b758a2162
verify_sha1 roms/original/astro.bin b902c941997c9d150a560435bf517c6a28137ecc

if [[ "$hash_failed" -ne 0 ]]; then
    echo
    echo "Build failed ROM verification."
    exit 1
fi

echo "PASS: Cartridge and Astrocade system ROMs match the required SHA-1 values."

echo
echo "[3/3] Package the standalone MAME test set"
package_dir="$(mktemp -d)"
trap 'rm -rf -- "$package_dir"' EXIT
mkdir -p "$package_dir/seawolf"
cp roms/original/astro.bin "$package_dir/astro.bin"
cp src/zout/seawolf.bin "$package_dir/seawolf/seawolf.bin"

rm -f roms/astrocde.zip
echo "+ zip -q roms/astrocde.zip astro.bin seawolf/seawolf.bin"
(
    cd "$package_dir"
    zip -q "$script_dir/roms/astrocde.zip" astro.bin seawolf/seawolf.bin
)
rm -rf -- "$package_dir"
trap - EXIT

echo "Created: roms/astrocde.zip"

echo
echo "Build complete: roms/astrocde.zip"
