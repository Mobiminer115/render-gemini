#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d "gl4es" ]; then
    echo "[1/4] Dang clone ma nguon goc ptitSeb/gl4es..."
    git clone --depth=1 https://github.com/ptitSeb/gl4es.git gl4es
fi

echo "[2/4] Dang ap dung cac ban va GeminiGL4ES cho iPhone 6s Plus -> 16 Pro Max..."
python3 scripts/apply_patches.py gl4es

IOS_SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG_CC="$(xcrun --sdk iphoneos --find clang)"
CLANG_CXX="$(xcrun --sdk iphoneos --find clang++)"

# Co toi uu hoa cho kien truc ARM64 bat dau tu Apple A9 (iPhone 6s Plus)
OPT_FLAGS="-arch arm64 -isysroot ${IOS_SDK_PATH} -miphoneos-version-min=12.0 -O3 -funroll-loops -fno-math-errno -fno-trapping-math -fPIC -fvisibility=default -D__ARM_NEON__ -DARM64 -DNOX11 -DNOEGL -DDEFAULT_ES=2"

echo "[3/4] Dang bien dich loi GL4ES voi CMake..."
rm -rf build_gl4es dist
mkdir -p build_gl4es dist
cd build_gl4es

cmake ../gl4es \
    -DCMAKE_SYSTEM_NAME=Darwin \
    -DCMAKE_OSX_SYSROOT="${IOS_SDK_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="arm64" \
    -DCMAKE_C_COMPILER="${CLANG_CC}" \
    -DCMAKE_CXX_COMPILER="${CLANG_CXX}" \
    -DCMAKE_C_FLAGS="${OPT_FLAGS}" \
    -DNOX11=ON \
    -DNOEGL=ON \
    -DSTATICLIB=ON \
    -DDEFAULT_ES=2

cmake --build . --config Release -j"$(sysctl -n hw.ncpu || echo 4)"
cd "$ROOT_DIR"

STATIC_LIB="$(find build_gl4es -name "libGL.a" -o -name "libgl4es.a" | head -n 1)"
if [ -z "$STATIC_LIB" ]; then
    echo "Loi: Khong tim thay file static lib sau khi build!"
    exit 1
fi

echo "[4/4] Dang dong goi Dynamic Library (.dylib) cho Amethyst-iOS..."
"${CLANG_CC}" ${OPT_FLAGS} \
    -dynamiclib \
    -Iinclude \
    src/ios_gemini_tier.m \
    -Wl,-force_load,"${STATIC_LIB}" \
    -framework Foundation \
    -framework UIKit \
    -install_name "@rpath/libgl4es_114.dylib" \
    -current_version 1.1.5 \
    -compatibility_version 1.0.0 \
    -o dist/libgl4es_114.dylib

# Tao them ban sao mang ten rieng de de quan ly
cp dist/libgl4es_114.dylib dist/libgemini_gl4es.dylib

# Ky ad-hoc (ldid / codesign) de TrollStore & Sideload nap dylib khong bi loi
codesign -f -s - dist/libgl4es_114.dylib || true
codesign -f -s - dist/libgemini_gl4es.dylib || true

echo "=========================================================="
echo " BUILD THANH CONG!"
echo " Output:"
ls -lh dist/
echo "=========================================================="
