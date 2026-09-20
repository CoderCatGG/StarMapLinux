{
  description = "KSA's StarMapLoader";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    dotnetCore = pkgs.dotnetCorePackages;
    dotnet-sdk = dotnetCore.sdk_10_0;
    dotnet-runtime = dotnetCore.runtime_10_0;

    version = "0.4.5";
    buildType = "Debug";
  
    runtimeDeps = with pkgs; [
      vulkan-loader
      icu
      # TODO remove x11 and wayland only compat
      libx11
      libxcursor
      libxi
    ];

    ksaDll = pkgs.requireFile {
      name = "KSA.dll";
      message = ''
        sfextract your install.
      '';
      sha256 = "e6eb25f6980b93a0f1e25568ff361c37154749a3d7bdf7247ba90aa0150b47a1";
    };

    star-map-types = pkgs.buildDotnetModule {
      pname = "StarMap.Types";
      inherit version;

      src = ./StarMap.Types/.;

      projectFile = "StarMap.Types.csproj";
      nugetDeps = ./deps.json;
      inherit dotnet-runtime dotnet-sdk buildType;

      packNupkg = true;
    };

    star-map-api = pkgs.buildDotnetModule {
      pname = "StarMap.API";
      inherit version;

      src = ./StarMap.API/.;

      projectFile = "StarMap.API.csproj";
      inherit dotnet-runtime dotnet-sdk buildType;

      postPatch = ''
        substituteInPlace StarMap.API.csproj --replace-fail 'Include="..\..\Import\KSA.dll"' 'Include="${ksaDll}"'
      '';

      packNupkg = true;
    };

    star-map-core = pkgs.buildDotnetModule {
      pname = "StarMap.Core";
      inherit version;

      src = ./StarMap.Core/.;

      projectFile = "StarMap.Core.csproj";
      nugetDeps = ./deps.json;
      inherit dotnet-runtime dotnet-sdk buildType;
      
      buildInputs = [
        star-map-api
	star-map-types
      ];

      postPatch = ''
        substituteInPlace StarMap.Core.csproj --replace-fail 'Include="..\..\Import\KSA.dll"' 'Include="${ksaDll}"'
      '';

      packNupkg = true;
    };

    star-map-loader = pkgs.buildDotnetModule {
      pname = "StarMap.Loader";
      inherit version;

      src = ./StarMap.Loader/.;

      projectFile = "StarMap.Loader.csproj";
      nugetDeps = ./deps.json;
      inherit dotnet-runtime dotnet-sdk runtimeDeps;

      buildInputs = [
        star-map-api
        star-map-core
	star-map-types
      ];

      postInstall = ''
        wrapProgram $out/lib/StarMap.Loader/StarMap.Loader \
          --unset WAYLAND_DISPLAY
      '';

      packNupkg = true;
    };

    star-map-launcher = pkgs.buildDotnetModule {
      pname = "StarMap.Launcher";
      inherit version;

      src = ./StarMap.Launcher/.;

      projectFile = "StarMap.Launcher.csproj";
      nugetDeps = ./deps.json;
      inherit dotnet-runtime dotnet-sdk runtimeDeps;

      buildInputs = [
        star-map-api
	star-map-core
        star-map-types
	star-map-loader
      ];
    };
  in {
    packages."x86_64-linux".default = star-map-loader;
    packages."x86_64-linux".loader = star-map-loader;
    packages."x86_64-linux".core = star-map-core;
    packages."x86_64-linux".api = star-map-api;
    packages."x86_64-linux".types = star-map-types;
    packages."x86_64-linux".launcher = star-map-launcher;

    devShells."x86_64-linux".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        dotnet-sdk
	nuget-to-json
      ];
    };
  };
}
