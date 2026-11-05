FROM ubuntu:22.04
RUN apt-get update

# Required deps for installer to run
RUN apt-get install -y --no-install-recommends \
    libx11-6 libx11-xcb1 libfontconfig1

ENV prefix=/lscc/diamond/3.14
COPY --chmod=0755 diamond/3.14.0.75.2_Diamond_lin.run /diamond.run
RUN /diamond.run --console --prefix "${prefix}"
RUN rm /diamond.run

# Required deps for pnmainc (console-mode Diamond) to start
RUN apt-get install -y --no-install-recommends \
    libglib2.0-0 libxrender1 libxext6 libsm6

# Required deps for synplify to start
RUN apt-get install -y --no-install-recommends \
    libgl1 libgstreamer-plugins-base1.0-0 libsqlite3-0 libxcomposite1 libgraphite2-3

# Recommended deps from Lattice Diamond 3.14 FPGA Libraries User Guide
# Without these, Synplify will segfault, but I'm not sure which one exactly is the culprit
RUN apt-get install -y --no-install-recommends \
    libjpeg-dev libieee1284-3 libusb-0.1.4 lsb-core libnss3 libxt6 libxi6 libxft2 libxslt1.1 \
    libxrandr2 libxdamage1 libxcursor1 libxinerama1 libxss1 libatk1.0-0 libcairo2 libpango-1.0-0 \
    pulseaudio libxcb-xinput0 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xkb1 \
    libxcb-xinerama0 libxkbcommon0 libxkbcommon-x11-0 libxcb-icccm4 libxcb-shape0 libxcb-cursor0 \
    libxv1 cdparanoia libopus0 libtheora0 libvisual-0.4-0 gstreamer1.0-plugins-base \
    libgl1-mesa-glx libxtst6 libdbus-1-3

RUN rm -rf /var/lib/apt/lists/*

# The 'bindir' variable is required by the diamond_env script
ENV bindir=${prefix}/bin/lin64
COPY --chmod=0755 <<'EOF' /entrypoint.sh
#!/bin/bash
source "${bindir}/diamond_env"
"$@" && exit
echo "Command failed: $?"
echo "Interactive shell:"
/bin/bash
EOF

ENTRYPOINT ["/entrypoint.sh"]
