diamond:
    #!/bin/bash
    export bindir=$(realpath "$HOME/lscc/diamond/3.14/bin/lin64")
    source "${bindir}/diamond_env"
    ${bindir}/pnmain

gen name:
    #!/bin/bash
    export bindir=$(realpath "$HOME/lscc/diamond/3.14/bin/lin64")
    source "${bindir}/diamond_env"
    ${bindir}/pnmainc src/{{ name }}.tcl

docker_build:
    docker build -t lattice-diamond:3.14.0.75.2 .

docker_gen name: docker_build
    # --network host, so it has the same MAC address as the host for node-locked licenses
    # -u "$(id -u):$(id -g)", so files are created with the same user/group as the host
    docker run \
        --interactive --tty \
        --network host \
        -u "$(id -u):$(id -g)" \
        --mount "type=bind,source=$(realpath diamond/ConsolidatedLicenseFile.lic),target=/lscc/diamond/3.14/license/license.dat" \
        --mount "type=bind,source=$(realpath src),target=/src" \
        --mount "type=bind,source=$(realpath output),target=/output" \
        lattice-diamond:3.14.0.75.2 \
        pnmainc src/{{ name }}.tcl
