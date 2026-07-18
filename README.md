# StarMap

A POC/Prototype arbitrary code modloader for Kitten Space Agency.  
Currently this loader can be ran with this functionality in the background, or as a dumb loader just loading mods.  
It makes use of Assembly Load Contexts to ensure mod dependencies are managed seperatly, reducing conflicts

## Installation

-   Download and unzip release from [Releases](https://github.com/StarMapLoader/StarMap/releases/latest).
-   Run StarMap.exe, this will fail and create a StarMapConfig.json.
-   Open StarMapConfig.json and set the location of your KSA installation.
    -   `GameLocation` should be set to the location where Kitten Space Agency was installed, pointing directly to that folder (e.g. `C:\\games\\Kitten Space Agency\\`)
    -   `RepositoryLocation` can be kept empty
-   Run StarMap.exe again, this should launch KSA and load your mods.

## Mod location

Mods can be placed in either of these two locations:

-   `Documents/My Games/Kitten Space Agency/mods/<ModName>/` (recommended, persists across game updates)
-   `<KSA Installation>/Content/<ModName>/`

StarMap uses the game's manifest system to discover mods from both locations.

## Mod creation

For more information on mod creation, check out the example mods: [StarMap-ExampleMods](https://github.com/StarMapLoader/StarMap-ExampleMods).

## Future plans

The goal is to create a modloader similar to the mod functionality in Factorio, where users can select mods in game taken from a remote repository, and that those mods than get installed after an automatic restart of the game  
It currently does this by using two processes to host the game itself seperately so it can restart  
The idea would be to have the repository just be an index of mods, versions and download locations, and that the download locations themselves are seperate (for example github releases)

## Building
### Build on windows
You require:
- dotnet 10.0
- A KSA installation

just use dotnet to build the package IN DEBUG MODE

### Build with nix
You require:
- nix (with flake support)
- A windows KSA installation

Before building:
- wine (or umu)

#### Getting a KSA.dll
This is needed in the build as StarMap depends on KSA.dll during building.
The following subsections describe how to do it manually, options like [bottles](https://usebottles.com) will do most of this for you.

##### Setting up a wine prefix
A wine prefix is just a directory, so just make new directory.
Then run `WINEPREFIX=(your prefix) winecfg` to set everything up.

##### Executing the KSA installer
Download the WINDOWS KSA installer from [ahwoo](https://ahwoo.com/app/100000/kitten-space-agency).
Copy the `.exe` into the `drive_c/users/(your username)/Downloads` folder.
Run `WINEPREFIX=(your prefix) wine run drive_c/users/(your username)/Downloads/setup_ksa_v2026.7.6.4939.exe` (The version is the version of the moment of me writing this, future versions will require small changes, please write CoderCatGG, as I am the sole "maintainer" and everyone else uses windows).

##### Extracting the KSA.dll into the nix store
Wait for the installer to finish and copy the KSA.dll into the nix store (`nix-store --add-fixed sha256 drive_c/'Program Files'/'Kitten Space Agency'/KSA.dll`).
This should output the store path and the sha256 hash `e6eb25f6980b93a0f1e25568ff361c37154749a3d7bdf7247ba90aa0150b47a1`.

#### Building the project
Now you can build/run the flake with `NIXPKGS_ALLOW_UNFREE=1 nix build/run --impure`.

##### Building subprojects
The default target is the loader (aka. "standalone").
If you want to change that, just specify the output. The laucher is `.#launcher`, core is `.#core`, etc.
If you every encounter problems, please try to first build the other internal dependencies.

## Credits

-   Lexi - [KSALoader](https://github.com/cheese3660/KsaLoader)
