{
  description = "Nix devshells for XiangShan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    gsim = {
      url = "github:OpenXiangShan/gsim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, gsim, ... }: let
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
        llvmPackages.bolt # for pgo
        clang
        gnumake # make
        dtc # device tree compiler
        flex
        autoconf
        bison
        # override mill & verilator to use our version
        (mill.overrideAttrs (finalAttrs: previousAttrs: {
          version = "0.12.15";
          src = fetchurl {
            url = "https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/${finalAttrs.version}/mill-dist-${finalAttrs.version}.exe";
            hash = "sha256-6hu6AeIg9M4guzMyR9JUor+bhlVMEMPX1+FmQewKdtg=";
          };
        }))
        # compile verilator with clang instead of gcc
        ((verilator.override { stdenv = clangStdenv; }).overrideAttrs (finalAttrs: previousAttrs: {
          version = "5.048";
          src = fetchFromGitHub {
            owner = "verilator";
            repo = "verilator";
            rev = "v${finalAttrs.version}";
            hash = "sha256-xvqqgbW7L07+NBYzGN2KLhwir58ByShxo4VVPI3pgZk=";
          };
          # use jemalloc by default
          buildInputs = previousAttrs.buildInputs ++ [
            jemalloc
          ];
          doCheck = false;
        }))
        gsim.packages.${system}.default

        # === debug ===
        (gtkwave.overrideAttrs (finalAttrs: previousAttrs: {
          # disable judy, it will cause a "abort: buffer overflow detected" error while opening xiangshan .fst waveforms
          configureFlags = builtins.filter (
            flag: flag != "--enable-judy"
          ) previousAttrs.configureFlags;
        }))

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
        echo "- $(verilator --version | head -n 1)"
        echo "- $(gsim --version | head -n 1)"
        echo "- $(mill --version | head -n 1)"
        echo "- $(gcc --version | head -n 1)"
        echo "- $(riscv64-unknown-linux-gnu-gcc --version | head -n 1)"
        echo "- $(clang --version | head -n 1)"
        echo "- $(java -version 2>&1 | head -n 1)"
        echo "You can press Ctrl + D to exit devshell."
        export LD_LIBRARY_PATH="${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        source $(pwd)/env.sh
      '';
    };
  };
}
