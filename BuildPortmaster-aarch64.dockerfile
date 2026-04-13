FROM monkeyx/retro_builder:arm64
WORKDIR /usr/local/app

ENV DEBIAN_FRONTEND=noninteractive

# Удаляем проблемный репозиторий Kitware, обновляем список пакетов и ставим зависимости
RUN rm -f /etc/apt/sources.list.d/kitware.list \
    && apt-get update \
    && apt-get install -y \
        cmake g++ clang \
        libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev \
        zlib1g-dev libavformat-dev libswscale-dev \
        libboost-dev libboost-filesystem-dev libboost-system-dev \
        libboost-thread-dev libboost-program-options-dev libboost-locale-dev libboost-iostreams-dev \
        qtbase5-dev libtbb-dev libluajit-5.1-dev liblzma-dev libsqlite3-dev libminizip-dev \
        qttools5-dev ninja-build ccache \
    && apt-get clean

# Устанавливаем более свежий CMake для поддержки presets
RUN apt-get remove -y cmake \
    && apt-get install -y libssl-dev \
    && wget https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5.tar.gz \
    && tar zxvf cmake-3.31.5.tar.gz \
    && cd cmake-3.31.5 \
    && ./bootstrap \
    && make \
    && make install \
    && cd .. \
    && rm -rf cmake-3.31.5*

CMD ["sh", "-c", " \
    cd /vcmi ; \
    ln -s /usr/lib/libSDL2.so /usr/lib/aarch64-linux-gnu/libSDL2.so ; \
    cmake --preset portmaster-release ; \
    cmake --build --preset portmaster-release ; \
    ldd /vcmi/out/build/portmaster-release/bin/vcmiclient | grep -e libboost -e libtbb -e libicu | awk 'NF == 4 { system(\"cp \" $3 \" /vcmi/out/build/portmaster-release/bin/\") }' \
"]
