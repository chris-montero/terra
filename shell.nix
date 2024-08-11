{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.lua5_1
    pkgs.luarocks
    pkgs.luajit
    pkgs.cairo
    pkgs.pango # needed for lgi
    pkgs.libev
    pkgs.pkg-config
    pkgs.xorg.libX11
    pkgs.xorg.libxcb
    pkgs.xorg.xcbutil
    pkgs.xcb-util-cursor
    pkgs.xorg.xcbutilerrors
    pkgs.xorg.xcbutilkeysyms
    pkgs.libxkbcommon

    pkgs.luajitPackages.lgi
    pkgs.lua51Packages.lgi
    pkgs.gobject-introspection
  ];

  shellHook = ''
    # Set environment variables for the libraries
    export CAIRO_DIR=${pkgs.cairo}
    export EV_DIR=${pkgs.libev}
    export LUAJIT_5_1_DIR=${pkgs.luajit}
    export X11_DIR=${pkgs.xorg.libX11}
    export XCB_DIR=${pkgs.xorg.libxcb}

    # Some jank to extract the header directory to pass to the includes
    export XCB_UTIL_DIR=${pkgs.xorg.xcbutil}
    export XCB_UTIL_DRV_DIR=$(nix-store --query --deriver $XCB_UTIL_DIR)
    export XCB_HEADER_DIR=$(nix-store --query --outputs $XCB_UTIL_DRV_DIR | grep "dev")

    export XCB_CURSOR_DIR=${pkgs.xcb-util-cursor}
    export XCB_ERRORS_DIR=${pkgs.xorg.xcbutilerrors}
    export XCB_KEYSYMS_DIR=${pkgs.xorg.xcbutilkeysyms}
    export XKBCOMMON_DIR=${pkgs.libxkbcommon}
    export XKBCOMMON_X11_DIR=${pkgs.libxkbcommon}

    # Add LuaJIT include directory
    export LUA_INCDIR=${pkgs.luajit}/include/luajit-2.1

    PKG_CONFIG_PATH=${pkgs.gobject-introspection}

    luarocks install --server=https://luarocks.org/dev tstation --lua-version=5.1 --local

    luarocks --lua-version=5.1 make --local \
      CAIRO_DIR="$CAIRO_DIR" EV_DIR="$EV_DIR" \
      LUAJIT_5_1_DIR="$LUAJIT_5_1_DIR" \
      X11_DIR="$X11_DIR" XCB_DIR="$XCB_DIR" \
      XCB_CURSOR_DIR="$XCB_CURSOR_DIR" \
      XCB_ERRORS_DIR="$XCB_ERRORS_DIR" \
      XCB_KEYSYMS_DIR="$XCB_KEYSYMS_DIR" \
      XKBCOMMON_DIR="$XKBCOMMON_DIR" \
      XKBCOMMON_X11_DIR="$XKBCOMMON_X11_DIR" \
      LUA_INCDIR="$LUA_INCDIR" \
      CFLAGS="-I$XCB_HEADER_DIR/include"

    export LUA_PATH="/home/nikolasd/.luarocks/share/lua/5.1/?.lua;;"
    export LUA_CPATH="/home/nikolasd/.luarocks/lib/lua/5.1/?.so;;"
  '';
}