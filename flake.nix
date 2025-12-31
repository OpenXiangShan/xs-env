{
  description = "Nix devshells for XiangShan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
          version = "0.12.15";
          src = fetchurl {
            url = "https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/${finalAttrs.version}/mill-dist-${finalAttrs.version}.exe";
            hash = "sha256-6hu6AeIg9M4guzMyR9JUor+bhlVMEMPX1+FmQewKdtg=";
          };
        }))
        (verilator.overrideAttrs (finalAttrs: previousAttrs: {
          version = "5.042";
          VERILATOR_SRC_VERSION = "v${finalAttrs.version}";
          src = fetchFromGitHub {
            owner = "verilator";
            repo = "verilator";
            rev = "v${finalAttrs.version}";
            hash = "sha256-+hfqOt429Kv4rZXEMz4LxNgBULAt/ewWY7mnQt2zpVU=";
          };
          # drop nixos upstream patches (previousAttrs.patches)
          # as 2aa260a03b67d3fe86bc64b8a59183f8dc21e117 already exists in 5.042
          patches = [
            (fetchpatch {
              # FIXME: apply this patch temporarily for better performance on XiangShan-chisel6/7, drop it after verilator mainline releases it
              # https://github.com/verilator/verilator/pull/6822: Optimize mux with UInt To OneHot
              url = "https://github.com/verilator/verilator/commit/bd38775ad2c1e4fffa4d56d4ef4f835ece216b39.patch";
              hash = "sha256-VWpxXi2swrOq+3IOKE4Ek5laVuXUdkoswlZGnnLgIOQ=";
            })
          ];
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
