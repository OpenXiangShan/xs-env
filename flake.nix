{
  description = "Nix devshells for XiangShan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # === tool ===
        wget
        git
        tmux
        curl
        time

        # === runtime ===
        python3
        python3Packages.psutil # for XiangShan/scripts/xiangshan.py
        openjdk

        # === toolchain ===
        gcc # host toolchain
        pkgsCross.riscv64.buildPackages.gcc # riscv64-unknown-elf-xxx toolchain
        llvm # for pgo
        clang
        gnumake # make
        dtc # device tree compiler
        flex
        autoconf
        bison
        # override mill & verilator to use our version
        (mill.overrideAttrs (finalAttrs: previousAttrs: {
          version = "0.12.3";
          src = fetchurl {
            url = "https://github.com/com-lihaoyi/mill/releases/download/${finalAttrs.version}/${finalAttrs.version}-assembly";
            hash = "sha256-hqzAuYadCciYPs/b6zloLUfrWF4rRtlBSMxSj7tLg7g=";
          };
        }))
        (verilator.overrideAttrs (finalAttrs: previousAttrs: {
          version = "5.028";
          VERILATOR_SRC_VERSION = "v${finalAttrs.version}";
          src = fetchFromGitHub {
            owner = "verilator";
            repo = "verilator";
            rev = "v${finalAttrs.version}";
            hash = "sha256-YgK60fAYG5575uiWmbCODqNZMbRfFdOVcJXz5h5TLuE=";
          };
          doCheck = false;
        }))

        # === debug ===
        gtkwave

        # === lib ===
        readline
        SDL2
        zlib
        zstd
        sqlite
      ];
      shellHook = ''
        echo "=== Welcome to XiangShan devshell! ==="
        echo "Version info:"
        echo "- $(verilator --version)"
        echo "- $(mill --version | head -n 1)"
        echo "- $(gcc --version | head -n 1)"
        echo "- $(riscv64-unknown-linux-gnu-gcc --version | head -n 1)"
        echo "- $(java -version 2>&1 | head -n 1)"
        echo "You can press Ctrl + D to exit devshell."
        export LD_LIBRARY_PATH="${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        source $(pwd)/env.sh
      '';
    };
  };
}
