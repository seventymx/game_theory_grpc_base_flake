/*
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  Author: Steffen70 <steffen@seventy.mx>
  Creation Date: 2024-07-25

  Contributors:
  - Contributor Name <contributor@example.com>
*/

{
  description = "This is a base flake that should be included in all service specific flakes.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    protos.url = "github:seventymx/game_theory_grpc_protos";
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        unstable = import inputs.nixpkgs { inherit system; };

        licenseHeader = ''
          @'
          ===================================================================
          This Source Code Form is subject to the terms of the Mozilla Public
          License, v. 2.0. If a copy of the MPL was not distributed with this
          file, You can obtain one at https://mozilla.org/MPL/2.0/.
          ===================================================================
          '@
        '';

        # certificateSettings is a JSON string that contains the path to the certificate (without the extension) and the password for the pfx file.
        certificateSettings = ''
          {
            "path": "../cert/localhost",
            "password": "fancyspy10"
          }
        '';
      in
      {
        devShell = unstable.mkShell {
          buildInputs = [
            unstable.nixfmt-rfc-style
            unstable.git
            unstable.powershell
            unstable.gnutar
          ];

          shellHook = ''
            # Set the shell to PowerShell - vscode will use this shell
            export SHELL="${unstable.powershell}/bin/pwsh"

            export PROTOBUF_PATH=${inputs.protos}

            export PHP_INTERFACE_PORT=5001
            export PLAYING_FIELD_PORT=5002
            export TIT_FOR_TAT_PORT=5003
            export FRIEDMAN_PORT=5004

            export CERTIFICATE_SETTINGS='${certificateSettings}'

            # Enter PowerShell and output the licenseHeader
            pwsh -NoExit -Command "& {
              Write-Host ${licenseHeader}
            }"

            # Exit when PowerShell exits
            exit 0
          '';
        };
      }
    );
}
