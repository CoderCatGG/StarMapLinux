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

    ksaLibs = pkgs.requireFile {
      name = "KSALibraries";
      message = ''
        Download KSA...
      '';
      hashMode = "recursive";
      sha256 = "01l6rap6mm6cnzidc05wj0gw28jickvvpybnkny2cbvgf2j1w2w4";
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
        substituteInPlace StarMap.API.csproj --replace-fail 'Include="..\..\Import\KSA.dll"' 'Include="${ksaLibs}\KSA.dll"'
        substituteInPlace StarMap.API.csproj --replace-fail 'Include="..\..\Import\Brutal.*.dll"' 'Include="${ksaLibs}\Brutal.*.dll"'
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
        substituteInPlace StarMap.Core.csproj --replace-fail 'Include="..\..\Import\KSA.dll"' 'Include="${ksaLibs}\KSA.dll"'
        substituteInPlace StarMap.Core.csproj --replace-fail 'Include="..\..\Import\Brutal.*.dll"' 'Include="${ksaLibs}\Brutal.*.dll" /><Reference Include="${ksaLibs}\Planet.*.dll"'

        substituteInPlace StarMap.Core.csproj --replace-fail \
		'<ProjectReference Include="..\StarMap.API\StarMap.API.csproj" />' \
		'<PackageReference Include="StarMap.API" Version="*" />'
        substituteInPlace StarMap.Core.csproj --replace-fail \
		'<ProjectReference Include="..\StarMap.Types\StarMap.Types.csproj" />' \
		'<PackageReference Include="StarMap.Types" Version="*" />'
      '';

      packNupkg = true;
    };

    star-map = pkgs.buildDotnetModule {
      pname = "StarMap";
      inherit version;

      src = ./StarMap/.;

      projectFile = "StarMap.csproj";
      nugetDeps = ./deps.json;
      inherit dotnet-runtime dotnet-sdk runtimeDeps;

      buildInputs = [
        star-map-api
        star-map-core
	star-map-types
      ];

      nativeBuildInputs = with pkgs; [
        makeWrapper
      ];

      postPatch = ''
	substituteInPlace StarMap.csproj --replace-fail \
		'<ProjectReference Include="..\StarMap.Core\StarMap.Core.csproj" />' \
		'<PackageReference Include="StarMap.Core" Version="*" />'
        substituteInPlace StarMap.csproj --replace-fail \
		'<ProjectReference Include="..\StarMap.Types\StarMap.Types.csproj" />' \
		'<PackageReference Include="StarMap.Types" Version="*" />'
      '';

      postFixup = ''
        cp ${star-map-core}/lib/StarMap.Core/StarMap.Core.deps.json $out/lib/StarMap/

        wrapProgram $out/lib/StarMap/StarMap \
          --unset WAYLAND_DISPLAY
      '';

      packNupkg = true;
    };
  in {
    packages."x86_64-linux".default = star-map;
    packages."x86_64-linux".loader = star-map;
    packages."x86_64-linux".core = star-map-core;
    packages."x86_64-linux".api = star-map-api;
    packages."x86_64-linux".types = star-map-types;

    devShells."x86_64-linux".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        dotnet-sdk
	nuget-to-json
      ];
    };
  };
}
