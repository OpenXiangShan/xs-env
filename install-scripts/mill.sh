# Install Mill

set -euo pipefail

echo "Installing mill wrapper..."
curl -fL --retry 3 https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh -o /usr/local/bin/mill
chmod +x /usr/local/bin/mill

echo "Pre-downloading mill..."
XIANGSHAN_BRANCH=${XIANGSHAN_BRANCH:-kunminghu-v3}
export MILL_VERSION=$(curl -fL --retry 3 https://raw.githubusercontent.com/OpenXiangShan/XiangShan/${XIANGSHAN_BRANCH}/.mill-version)
mill --version
