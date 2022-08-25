FROM mono:latest
LABEL author="https://github.com/Atlinx/custom-godot-ci/graphs/contributors"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Install stuff required to export games
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      git-lfs \
      python \
      python-openssl \
      unzip \
      wget \
      zip \
      rsync \
      && rm -rf /var/lib/apt/lists/*

# Install stuff required to build Godot from source
# https://docs.godotengine.org/en/stable/development/compiling/compiling_for_x11.html
RUN apt-get install -y --no-install-recommends \
    build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev \
    libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev yasm

ARG GODOT_COMMIT_HASH="82175a6c2eabcf17fb622f3937d2bffa46d2d476"
ARG SG_PHYSICS_COMMIT_HASH="312a8f87c3c63ab2e6fb6928b3c11931e34699b2"

RUN git clone https://github.com/godotengine/godot.git && cd godot && git checkout ${GODOT_COMMIT_HASH}
RUN git clone https://gitlab.com/snopek-games/sg-physics-2d.git && cd sg-physics-2d && git checkout ${SG_PHYSICS_COMMIT_HASH}
RUN curl -LO https://curl.haxx.se/ca/cacert.pem \
    cert-sync --user cacert.pem

RUN cd godot \
    scons p=linux tools=yes module_mono_enabled=yes mono_glue=no custom_modules=../sg-physics-2d/godot/modules \
    bin/godot.windows --generate-mono-glue modules/mono/glue \
    scons p=linux tools=yes module_mono_enabled=yes mono_glue=no custom_modules=../sg-physics-2d/godot/modules

RUN mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/templates/${GODOT_VERSION}.${RELEASE_NAME}.mono \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64.zip \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless.64 /usr/local/bin/godot \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64/GodotSharp /usr/local/bin/GodotSharp \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/templates/${GODOT_VERSION}.${RELEASE_NAME}.mono \
    && rm -f Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64.zip

ADD getbutler.sh /opt/butler/getbutler.sh
RUN bash /opt/butler/getbutler.sh
RUN /opt/butler/bin/butler -V

ENV PATH="/opt/butler/bin:${PATH}"