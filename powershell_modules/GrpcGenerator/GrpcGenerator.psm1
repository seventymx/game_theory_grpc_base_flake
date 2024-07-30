# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Author: Steffen70 <steffen@seventy.mx>
# Creation Date: 2024-07-30
#
# Contributors:
# - Contributor Name <contributor@example.com>

$ErrorActionPreference = "Stop"

$successMessageFormat = "Successfully generated {0} gRPC files in the '{1}' directory."
$defaultGeneratedDirectory = "generated"

function Clear-GeneratedDirectory {
    param (
        [string]$GeneratedDirectory
    )
    if (Test-Path $GeneratedDirectory) {
        Remove-Item -Recurse -Force $GeneratedDirectory | Out-Null
    }
    New-Item -ItemType Directory -Path $GeneratedDirectory | Out-Null
}

function Build-ProtocCommand {
    param (
        [string]$BaseCommand,
        [string[]]$ProtosArray,
        [string]$ProtoPath,
        [string]$GeneratedDirectory,
        [string]$CurrentDirectory
    )

    $command = $BaseCommand

    foreach ($proto in $ProtosArray) {
        $command += " $ProtoPath/${proto}.proto"
    }

    return $command
}

function Test-Prerequisite {
    param (
        [string]$Command
    )

    $command = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-Output "$($Command.Substring(0, 1).ToUpper() + $Command.Substring(1)) is not installed. Add $Command to your development shell and try again."
        return $false
    }

    return $true
}

function Update-PythonGrpc {
    param (
        [string[]]$ProtosArray
    )

    # Check if Python is installed
    if (-not (Test-Prerequisite "python3")) {
        return
    }

    # Configuration
    $protoPath = $env:PROTOBUF_PATH
    $baseCommand = "python -m grpc_tools.protoc --proto_path=$protoPath --python_out=./$defaultGeneratedDirectory --grpc_python_out=./$defaultGeneratedDirectory"

    # Clear generated directory
    Clear-GeneratedDirectory -GeneratedDirectory $defaultGeneratedDirectory

    # Build and execute the protoc command
    $command = Build-ProtocCommand -BaseCommand $baseCommand -ProtosArray $ProtosArray -ProtoPath $protoPath -GeneratedDirectory $defaultGeneratedDirectory -CurrentDirectory $PWD
    Invoke-Expression $command

    Write-Output ($successMessageFormat -f "Python", $defaultGeneratedDirectory)
}

function Update-PhpGrpc {
    param (
        [string[]]$ProtosArray
    )

    # Check if PHP is installed
    if (-not (Test-Prerequisite "php")) {
        return
    }

    # Configuration
    $protoPath = $env:PROTOBUF_PATH
    $baseCommand = "protoc --proto_path=$protoPath --php_out=./$defaultGeneratedDirectory --grpc_out=./$defaultGeneratedDirectory --plugin=protoc-gen-grpc=$(which grpc_php_plugin)"

    # Clear generated directory
    Clear-GeneratedDirectory -GeneratedDirectory $defaultGeneratedDirectory

    # Build and execute the protoc command
    $command = Build-ProtocCommand -BaseCommand $baseCommand -ProtosArray $ProtosArray -ProtoPath $protoPath -GeneratedDirectory $defaultGeneratedDirectory -CurrentDirectory $PWD
    Invoke-Expression $command

    # Generate the autoload file to import the generated files
    composer dump-autoload --quiet

    Write-Output ($successMessageFormat -f "PHP", $defaultGeneratedDirectory)
}

function Update-GoGrpc {
    param (
        [string[]]$ProtosArray
    )

    # Check if Go is installed
    if (-not (Test-Prerequisite "go")) {
        return
    }

    # Configuration
    $protoPath = $env:PROTOBUF_PATH
    $currentDirectoryName = Split-Path $PWD -Leaf
    $baseCommand = "protoc --proto_path=$protoPath --go_out=.. --go-grpc_out=.."

    # Clear generated directory
    Clear-GeneratedDirectory -GeneratedDirectory $defaultGeneratedDirectory

    # Add package mapping options for each proto file
    foreach ($proto in $ProtosArray) {
        $baseCommand += " --go_opt=M${proto}.proto=${currentDirectoryName}/${defaultGeneratedDirectory}/${proto}"
        $baseCommand += " --go-grpc_opt=M${proto}.proto=${currentDirectoryName}/${defaultGeneratedDirectory}/${proto}"
    }

    # Build and execute the protoc command
    $command = Build-ProtocCommand -BaseCommand $baseCommand -ProtosArray $ProtosArray -ProtoPath $protoPath -GeneratedDirectory $defaultGeneratedDirectory -CurrentDirectory $PWD

    Invoke-Expression $command

    Write-Output ($successMessageFormat -f "Go", $defaultGeneratedDirectory)
}

Export-ModuleMember -Function Update-PythonGrpc, Update-PhpGrpc, Update-GoGrpc
