#!/bin/bash -e

FMT_VERSION="10.2.1"
JSON_VERSION="3.11.3"
ZLIB_VERSION="1.3"
ZSTD_VERSION="1.5.5"
LZ4_VERSION="1.9.4"
BOOST_VERSION="1.84.0"

cmake_install() {
    cmake . -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON "$@"
    ninja install
}

# $1: url $2: dir name $3: sha256sum
download_extract() {
    local filename
    filename="$(basename "$1")"
    wget "$1" -O "$filename"
    echo "$3 $filename" > "$filename".sha256sum
    sha256sum -c "$filename".sha256sum
    bsdtar xf "$filename"
    pushd "$2"
}

info() {
    echo -e "\e[1m--> Downloading and building $1...\e[0m"
}

info "fmt ${FMT_VERSION}"
download_extract "https://github.com/fmtlib/fmt/releases/download/${FMT_VERSION}/fmt-${FMT_VERSION}.zip" "fmt-${FMT_VERSION}" 312151a2d13c8327f5c9c586ac6cf7cddc1658e8f53edae0ec56509c8fa516c9
cmake_install -DFMT_DOC=OFF -DFMT_TEST=OFF
popd

info "nlohmann_json ${JSON_VERSION}"
download_extract "https://github.com/nlohmann/json/releases/download/v${JSON_VERSION}/json.tar.xz" json d6c65aca6b1ed68e7a182f4757257b107ae403032760ed6ef121c9d55e81757d
cmake_install -DJSON_BuildTests=OFF
popd

info "zlib ${ZLIB_VERSION}"
download_extract "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.xz" "zlib-${ZLIB_VERSION}" 8a9ba2898e1d0d774eca6ba5b4627a11e5588ba85c8851336eb38de4683050a7
cmake_install -DCMAKE_POLICY_DEFAULT_CMP0069=NEW
# delete shared libraies as we can't use them in the final image
rm -v /usr/local/lib/libz.so*
popd

info "zstd ${ZSTD_VERSION}"
download_extract "https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz" "zstd-${ZSTD_VERSION}"/build/cmake 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
cmake_install -DZSTD_BUILD_PROGRAMS=OFF -DBUILD_TESTING=OFF -GNinja -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF
popd

info "lz4 ${LZ4_VERSION}"
download_extract "https://github.com/lz4/lz4/archive/refs/tags/v${LZ4_VERSION}.tar.gz" "lz4-${LZ4_VERSION}/build/cmake" 0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
cmake_install -DLZ4_BUILD_CLI=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF -DLZ4_BUILD_LEGACY_LZ4C=OFF
# we need to adjust the exported name of the static library
cat << EOF >> /usr/local/lib/cmake/lz4/lz4Targets.cmake
# Injected commands by yuzu-room builder script
add_library(lz4::lz4 ALIAS LZ4::lz4_static)
EOF
popd

info "boost ${BOOST_VERSION}"
download_extract "https://github.com/boostorg/boost/releases/download/boost-1.84.0/boost-1.84.0.tar.xz" "boost-${BOOST_VERSION}" 2e64e5d79a738d0fa6fb546c6e5c2bd28f88d268a2a080546f74e5ff98f29d0e
# Boost use its own ad-hoc build system
# we only enable what yuzu needs
./bootstrap.sh --with-libraries=context,container,system,headers
./b2 -j "$(nproc)" install --prefix=/usr/local
popd

# fake xbyak for non-amd64 (workaround a CMakeLists bug in yuzu)
echo '!<arch>' > /usr/local/lib/libxbyak.a
