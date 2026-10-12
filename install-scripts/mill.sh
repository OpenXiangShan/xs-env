# Install Mill

set -euo pipefail

echo "Installing mill..."
curl -fL --retry 3 https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh -o /usr/local/bin/mill
chmod +x /usr/local/bin/mill

if [ -f XiangShan/.mill-version ]; then
    echo "Pre-installing required mill version for XiangShan..."
    MILL_VERSION=$(cat XiangShan/.mill-version) mill --version
fi
if [ -f NutShell/.mill-version ]; then
    echo "Pre-installing required mill version for NutShell..."
    MILL_VERSION=$(cat NutShell/.mill-version) mill --version
fi
if [ !-f XiangShan/.mill-version ] && [ ! -f NutShell/.mill-version ]; then
    echo "No .mill-version file found in XiangShan or NutShell, skipping pre-installation of mill versions."
fi
