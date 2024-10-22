# got from https://github.com/NixOS/nixpkgs/blob/5715b0743d28e2da129d05028137a374c0639060/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/tg_owt.nix
let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs { };
in
{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  cmake,
  crc32c,
  python3,
  libjpeg,
  openssl,
  libopus,
  ffmpeg,
  openh264,
  libvpx,
  libXi,
  libXfixes,
  libXtst,
  libXcomposite,
  libXdamage,
  libXext,
  libXrender,
  libXrandr,
  glib,
  abseil-cpp,
  pipewire,
  mesa,
  libGL,
  unstableGitUpdater,
  darwin,
}:

stdenv.mkDerivation {
  pname = "tg_owt";
  version = "0-unstable-2024-08-04";

  src = fetchFromGitHub {
    owner = "desktop-app";
    repo = "tg_owt";
    rev = "dc17143230b5519f3c1a8da0079e00566bd4c5a8";
    sha256 = "sha256-7j7hBIOXEdNJDnDSVUqy234nkTCaeZ9tDAzqvcuaq0o=";
    fetchSubmodules = true;
  };

  patches = [
    # Remove usage of AVCodecContext::reordered_opaque
    (fetchpatch2 {
      name = "webrtc-ffmpeg-7.patch";
      url = "https://webrtc.googlesource.com/src/+/e7d10047096880feb5e9846375f2da54aef91202%5E%21/?format=TEXT";
      decode = "base64 -d";
      stripLen = 1;
      extraPrefix = "src/";
      hash = "sha256-EdwHeVko8uDsP5GTw2ryWiQgRVCAdPc1me6hySdiwMU=";
    })
  ];

  enableParallelBuilding = true;

  postPatch = lib.optionalString stdenv.isLinux ''
    substituteInPlace src/modules/desktop_capture/linux/wayland/egl_dmabuf.cc \
      --replace '"libEGL.so.1"' '"${libGL}/lib/libEGL.so.1"' \
      --replace '"libGL.so.1"' '"${libGL}/lib/libGL.so.1"' \
      --replace '"libgbm.so.1"' '"${mesa}/lib/libgbm.so.1"'
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs =
    [
      openssl
      libjpeg
      libopus
      ffmpeg
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      glib
      libXi
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrender
      libXrandr
      libXtst
      pipewire
      mesa
      libGL
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin (
      with darwin.apple_sdk.frameworks;
      [
        Cocoa
        AppKit
        IOKit
        IOSurface
        Foundation
        AVFoundation
        CoreMedia
        VideoToolbox
        CoreGraphics
        CoreVideo
        Metal
        MetalKit
        CoreFoundation
        ApplicationServices
      ]
    );

  propagatedBuildInputs = [
    abseil-cpp
    crc32c
    openh264
    libvpx
  ];

  cmakeFlags = [
    # Building as a shared library isn't officially supported and may break at any time.
    (lib.cmakeBool "BUILD_SHARED_LIBS" false)
  ];

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "Fork of Google's webrtc library for telegram-desktop";
    homepage = "https://github.com/desktop-app/tg_owt";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
