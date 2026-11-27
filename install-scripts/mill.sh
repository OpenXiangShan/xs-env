# Install Mill

set -euo pipefail

WORKDIR="$(mktemp -d)"
INSTALLDIR="/usr/local/share/mill/download"

function cleanup {
    rm -rf -- "${WORKDIR}"
}
trap cleanup EXIT

cd "${WORKDIR}"

echo "Installing mill wrapper..."
curl -fL --retry 3 https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh -o mill
chmod +x mill

echo "Pre-downloading mill..."
XIANGSHAN_BRANCH=${XIANGSHAN_BRANCH:-kunminghu-v3}
BUNDLED_MILL_VERSION="$(curl -fL --retry 3 "https://raw.githubusercontent.com/OpenXiangShan/XiangShan/${XIANGSHAN_BRANCH}/.mill-version")"
if [ -z "${BUNDLED_MILL_VERSION}" ]; then
    echo "No Mill version specified by XiangShan/${XIANGSHAN_BRANCH}" >&2
    exit 1
fi
PATH="${WORKDIR}:${PATH}" MILL_VERSION="${BUNDLED_MILL_VERSION}" MILL_DOWNLOAD_PATH="${WORKDIR}/download" ./mill --version

# By default mill wrapper loads the mill binary from ~/.cache/mill/download, but we want to use a bundled mill instead.
# Patch the mill wrapper to try loading the bundled mill binary from $INSTALLDIR/download first.
if ! awk -v BUNDLED_DIR="${INSTALLDIR}" '
    { print }
    $0 == "try_to_use_system_mill" {
        print ""
        printf "MILL_BUNDLED=\"%s/${MILL##*/}\"\n", BUNDLED_DIR
        print "if [ ! -s \"$MILL\" ] && [ -s \"$MILL_BUNDLED\" ] && [ -x \"$MILL_BUNDLED\" ]; then"
        print "  MILL=\"$MILL_BUNDLED\""
        print "fi"
        HOOKS++
    }
    END { if (HOOKS != 1) exit 1 }
' mill > mill-patched; then
    echo "Cannot add the bundled Mill lookup: unexpected wrapper format" >&2
    exit 1
fi

install -d -m 0755 "${INSTALLDIR}"
install -m 0755 download/* "${INSTALLDIR}"
install -m 0755 mill-patched /usr/local/bin/mill
