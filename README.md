XiangShan Frontend Develop Environment
==================

[![CI](https://github.com/OpenXiangShan/xs-env/actions/workflows/main.yml/badge.svg)](https://github.com/OpenXiangShan/xs-env/actions/workflows/main.yml)

# TLDR

使用以下脚本来布署香山开发环境，**部署脚本只需运行一次.**：

This script will setup XiangShan develop environment automatically. Note that `./setup-tools.sh` and `setup.sh` only need to be run **ONCE**.

```sh
git clone https://github.com/OpenXiangShan/xs-env
cd xs-env
sudo -s ./setup-tools.sh # use apt to install dependencies, you may modify it to use different pkg manager
source setup.sh # prepare tools, test develop env using a small project
```

该脚本会从 apt.llvm.org 安装 LLVM 工具链到 `/usr/lib/llvm-VERSION`（Ubuntu 26.04 使用 LLVM 21，其余版本使用 LLVM 19），并创建 `/usr/local/llvm` 链接指向对应版本。GraalVM JDK 21 安装到 `/opt/graalvm-jdk-21`。LLVM 命令默认带版本后缀（例如 `clang-21`）。如需使用不带版本后缀的命令，请在 profile（例如 `~/.bashrc`）中加入以下配置：

This script installs the LLVM toolchain from apt.llvm.org under `/usr/lib/llvm-VERSION` (LLVM 21 on Ubuntu 26.04 and LLVM 19 on older releases), then creates `/usr/local/llvm` as a link to the selected version. GraalVM JDK 21 is installed under `/opt/graalvm-jdk-21`. LLVM commands use a version suffix by default (for example, `clang-21`). To use commands without the version suffix, add the following lines to your profile (e.g. `~/.bashrc`) after running the script:

```sh
echo 'export PATH="/usr/local/llvm/bin:${PATH}"' >> ~/.bashrc
echo 'export PATH="/opt/graalvm-jdk-21/bin:${PATH}"' >> ~/.bashrc
echo 'export JAVA_HOME="/opt/graalvm-jdk-21"' >> ~/.bashrc
```

使用 `--help` 参数查看脚本的更多选项：

Use `--help` to see more options of the script:

```sh
./setup-tools.sh --help
```

由于香山 `master` 分支更新频繁，此仓库中的 submodule 默认追踪香山主线分支上的一个稳定提交，**并不是香山及其他工具的最新版本**。要更新各子仓库到最新版本，可以运行:

Due to the frequent updates of the Xiangshan `master` branch, the submodule in this repo tracks a stable commit on the Xiangshan master branch by default, **not the latest version of Xiangshan and the other tools**. To update each submodule to the latest version, run:

```sh
source update-submodule.sh
```

**环境部署成功后，每次要使用开发环境时，只需使用以下命令配置环境变量**：

After XiangShan Develop Environment setup, use the following script **every time** before using XiangShan Develop Environment.

```sh
cd xs-env
source ./env.sh # setup XiangShan environment variables
```

# Document

详细使用方式请参考完整文档:

For further instructions, see:

[XiangShan Frontend Develop Environment Document](https://docs.xiangshan.cc/zh-cn/latest/tools/xsenv/)
