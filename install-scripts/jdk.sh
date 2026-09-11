# Install GraalVM JDK

set -euo pipefail

JDK_VERSION=21 # do not change this unless tested, XiangShan does not compile with JDK 25 yet

# GraalVM has better performance than openjdk,
# so install it instead of apt openjdk.
echo "Installing GraalVM JDK ${JDK_VERSION}..."

case "$(uname -m)" in
    x86_64) ARCH="linux-x64" ;;
    aarch64) ARCH="linux-aarch64" ;;
    *) echo "Unsupported architecture for GraalVM JDK: $(uname -m)"; exit 1 ;;
esac

curl -fLO --retry 3 "https://download.oracle.com/graalvm/${JDK_VERSION}/latest/graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz"
mkdir -p "/opt/graalvm-jdk-${JDK_VERSION}"
tar -xzf "graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz" \
    -C "/opt/graalvm-jdk-${JDK_VERSION}" --strip-components=1
rm "graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz"

echo "Hint: please add the following lines to your ~/.bashrc or ~/.zshrc to use GraalVM JDK ${JDK_VERSION}:"
echo 'export PATH="/opt/graalvm-jdk-'${JDK_VERSION}'/bin:${PATH}"'
echo 'export JAVA_HOME="/opt/graalvm-jdk-'${JDK_VERSION}'"'

export PATH="/opt/graalvm-jdk-${JDK_VERSION}/bin:${PATH}"
export JAVA_HOME="/opt/graalvm-jdk-${JDK_VERSION}"
