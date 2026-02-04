{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo-tauri,
  cargo,
  rustc,
  jq,
  libsoup_3,
  moreutils,
  nodejs,
  openssl,
  pkg-config,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  rustPlatform,
  webkitgtk_4_1,
  wrapGAppsHook3,
  nix-update-script,
  writeShellApplication,
}:
let
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "afadil";
    repo = "wealthfolio";
    rev = "v${version}";
    hash = "sha256-pLiSidcuRTcykHDgW2pw+h0t/42g6u3LlioSEDA0lIo=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) src pname version;
    pnpm = pnpm_9;
    fetcherVersion = 1;
    hash = "sha256-TcoyNIVb/aDgXIsNDvzTMfsewmefU9ck+uSHv/tbH/k=";
  };

  meta = {
    description = "Beautiful Private and Secure Desktop Investment Tracking Application";
    homepage = "https://wealthfolio.app/";
    license = lib.licenses.agpl3Only;
    mainProgram = "wealthfolio";
    maintainers = with lib.maintainers; [ kilianar ];
    platforms = lib.platforms.linux;
  };
in
{
  wealthfolio = stdenv.mkDerivation (finalAttrs: {
    pname = "wealthfolio";

    inherit version src pnpmDeps meta;

    cargoRoot = "src-tauri";
    buildAndTestSubdir = finalAttrs.cargoRoot;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs)
        pname
        version
        src
        cargoRoot
        ;
      hash = "sha256-R6lU4BPFlFxQqxmP5EWQsYwe1QGIlKVhp/iNiD9pKQo=";
    };

    nativeBuildInputs = [
      cargo-tauri.hook
      jq
      moreutils
      nodejs
      pkg-config
      pnpmConfigHook
      pnpm_9
      rustPlatform.cargoSetupHook
      wrapGAppsHook3
    ];

    buildInputs = [
      libsoup_3
      openssl
      webkitgtk_4_1
    ];

    postPatch = ''
      jq \
        '.plugins.updater.endpoints = [ ]
        | .bundle.createUpdaterArtifacts = false' \
        src-tauri/tauri.conf.json \
        | sponge src-tauri/tauri.conf.json
    '';

    passthru.updateScript = nix-update-script { };
  });

  wealthfolio-server = let
    wealthfolio-server-unwrapped = stdenv.mkDerivation (finalAttrs: {
      pname = "wealthfolio-server-unwrapped";

      inherit version src pnpmDeps;
      meta = meta // {
        mainProgram = "wealthfolio-server";
      };

      cargoRoot = "src-server";
      buildAndTestSubdir = finalAttrs.cargoRoot;
      cargoBuildType = "release";

      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (finalAttrs)
          pname
          version
          src
          cargoRoot
          ;
        hash = "sha256-Yg03IwW+T6/3UEvZ3TtrWvSV8czhQ622/BjRjUXIo6k=";
      };

      nativeBuildInputs = [
        nodejs
        pkg-config
        pnpmConfigHook
        pnpm_9
        rustPlatform.cargoSetupHook
        rustPlatform.cargoBuildHook
        rustPlatform.cargoInstallHook
        cargo
        rustc
      ];

      buildInputs = [
        openssl
      ];

      buildPhase = ''
        runHook preBuild

        pnpm tsc && pnpm vite build

        runHook cargoBuildHook
        runHook cargoInstallPostBuildHook

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        runHook cargoInstallHook

        mkdir -p "$out/share"
        cp -a dist "$out/share/wealthfolio-web"

        runHook postInstall
      '';
    });
  in writeShellApplication {
    name = "wealthfolio-server";
    inherit (wealthfolio-server-unwrapped) meta;

    text = ''
      export WF_STATIC_DIR="''${WF_STATIC_DIR:-${wealthfolio-server-unwrapped}/share/wealthfolio-web}"

      exec ${lib.meta.getExe wealthfolio-server-unwrapped} "$@"
    '';
  };
}
