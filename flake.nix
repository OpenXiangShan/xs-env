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
          version = "0.12.17";
          src = fetchurl {
            url = "https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/${finalAttrs.version}/mill-dist-${finalAttrs.version}.exe";
            hash = "sha256-3GF4viq2IPogziWwVlOPOWNJS1KszdjFFtfDIe5gNqs=";
          };
        }))
        # compile verilator with clang instead of gcc
        ((verilator.override { stdenv = clangStdenv; }).overrideAttrs (finalAttrs: previousAttrs: {
          version = "5.052";
          src = fetchFromGitHub {
            owner = "verilator";
            repo = "verilator";
            rev = "v${finalAttrs.version}";
            hash = "sha256-3xeodLkal/crtcB091lthUe/7/wC+sjAYRqNyl7/kv0=";
          };
          # use jemalloc by default
          buildInputs = previousAttrs.buildInputs ++ [
            jemalloc
          ];
          # FIXME: remove the following postPatch override after the fix is in some stable nixpkgs release
          # https://github.com/NixOS/nixpkgs/commit/ca62b9d68eb889f791e578eb657cff190d0da9fe
          postPatch = ''
            patchShebangs bin/* src/* nodist/* docs/bin/* examples/xml_py/* \
            test_regress/{driver.py,t/*.{pl,pf}} \
            test_regress/t/t_a1_first_cc.py \
            test_regress/t/t_a2_first_sc.py \
            ci/* ci/docker/run/* ci/docker/run/hooks/* ci/docker/buildenv/build.sh
            # verilator --gdbbt uses /bin/sh to test if gdb works.
            substituteInPlace bin/verilator --replace-fail "/bin/sh" "${bash}/bin/sh"
          '';
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
