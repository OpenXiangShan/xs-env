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

[XiangShan Frontend Develop Environment Document](https://xiangshan-doc.readthedocs.io/zh_CN/latest/tools/xsenv/)
