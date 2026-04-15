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
        qtbase5-dev libtbb-dev libluajit-5.1-dev liblzma-dev libsqlite3-dev libminizip-dev \
        qttools5-dev ninja-build ccache \
        wget python3-dev libbz2-dev libicu-dev \
    && apt-get clean

# Собираем Boost 1.74.0 из исходников (требуется для VCMI >=1.7.3)
RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.74.0/source/boost_1_74_0.tar.gz \
    && tar xzf boost_1_74_0.tar.gz \
    && cd boost_1_74_0 \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=date_time,filesystem,locale,program_options,system,thread,iostreams \
    && ./b2 install -j$(nproc) \
    && cd .. \
    && rm -rf boost_1_74_0*

# Удаляем системный Boost, чтобы избежать конфликтов
RUN apt-get remove -y libboost-dev libboost-*-dev \
    && apt-get autoremove -y

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
    # Исправляем симлинк SDL2, если он уже существует — не проблема
    ln -sf /usr/lib/libSDL2.so /usr/lib/aarch64-linux-gnu/libSDL2.so ; \
    # Конфигурируем с отключением MMAI
    cmake --preset portmaster-release -DENABLE_MMAI=OFF ; \
    cmake --build --preset portmaster-release ; \
    ldd /vcmi/out/build/portmaster-release/bin/vcmiclient | grep -e libboost -e libtbb -e libicu | awk 'NF == 4 { system(\"cp \" $3 \" /vcmi/out/build/portmaster-release/bin/\") }' \
"]
