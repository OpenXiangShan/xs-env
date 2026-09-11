# Install Mill

set -euo pipefail

echo "Installing mill..."
curl -fL --retry 3 https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh -o /usr/local/bin/mill
chmod +x /usr/local/bin/mill
