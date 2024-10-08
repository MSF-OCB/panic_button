{
  lib,
  version,
  production ? true,
  stdenv,
  elmPackages,
  nodePackages,
}:

let
  dist = "dist";
  mkDerivation =
    {
      srcs ? ./elm-srcs.nix,
      src,
      pname,
      srcdir ? "./src",
      targets ? [ ],
      registryDat ? ./registry.dat,
    }:
    stdenv.mkDerivation {
      inherit pname version src;

      buildInputs = [
        elmPackages.elm
        nodePackages.uglify-js
      ];

      preBuildPhases = [ "setupElmStuffPhase" ];

      setupElmStuffPhase = elmPackages.fetchElmDeps {
        elmPackages = import srcs;
        elmVersion = elmPackages.elm.version;
        inherit registryDat;
      };

      buildPhase =
        let
          elmfile = module: "${srcdir}/${builtins.replaceStrings [ "." ] [ "/" ] module}.elm";
          build_module =
            out: module:
            let
              out_file = "${out}/generated/${module}.js";
            in
            ''
              echo "compiling ${elmfile module}"
              elm make --optimize ${elmfile module} --output ${out_file}
              ${lib.optionalString production ''
                echo "minifying ${out_file}"
                uglifyjs ${out_file} \
                         --compress \
                         'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe,passes=2' \
                  | uglifyjs --mangle --output ${out_file}
              ''}
            '';
        in
        ''
          mkdir -p ${dist}/
          ${lib.concatMapStrings (build_module dist) targets}
        '';

      installPhase = ''
        mkdir -p $out
        echo "copying assets"
        cp -r index.html assets ${dist}/generated $out
      '';
    };
in
mkDerivation {
  pname = "nixos_server_lock_frontend";
  src = builtins.path {
    path = ./.;
    name = "frontend";
  };
  targets = [ "Main" ];
}
