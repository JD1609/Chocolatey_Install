
# Start as admin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Maximized
    exit;
}



#region Configurations
$configs = @('core', 'gui', 'dev', 'full')

$config_core_pkgs = @()
$config_gui_pkgs = $config_core_pkgs + @('chocolateygui')
$config_dev_pkgs = $config_gui_pkgs + @('ripgrep', 'dotnet-6.0-sdk', 'git', 'gitkraken', 'visualstudio2022community', 'sql-server-management-studio', 'vscode', 'postman')
$config_full_pkgs = $config_dev_pkgs + @('adobereader', 'googledrive', 'lightshot', 'vlc', 'winrar', 'spotify', 'teamspeak', 'discord', 'steam-client', 'whatsapp')

$path_folder = "C:\path"
$ripgrep_bat = "ripg.bat"
$ripgrep_bat_full_path = $path_folder + "\" + $ripgrep_bat
#endregion

#region Functions

function InstallCore { # Install chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
}

function InstallPackage {
    param ($pkg)
    
    choco install $pkg
}

function ShowHelp{
    Write-Host "Core - installs:" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "chocolatey"
    Write-Host ""
    
    Write-Host "Gui - installs:" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "chocolatey"
    $config_gui_pkgs
    Write-Host ""
    
    Write-Host "Dev - installs:" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "chocolatey"
    $config_dev_pkgs
    Write-Host ""
    
    Write-Host "Full - installs:" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "chocolatey"
    $config_full_pkgs
    Write-Host ""
}

#endregion


do {
    $installation_type = Read-Host -Prompt 'Enter installation type [core, gui, dev, full] ("?" for help)'
    $installation_type = $installation_type.ToLower()

    if ($installation_type -eq "?"){
        ShowHelp
    }
} 
while (-not $configs.Contains($installation_type))



# Install chocolatey
InstallCore


# Install packages
if ($installation_type -eq "core"){
}
elseif ($installation_type -eq "gui") {
    foreach ($pkg in $config_gui_pkgs) {
        InstallPackage($pkg)
    }
}
elseif ($installation_type -eq "dev") {
    foreach ($pkg in $config_dev_pkgs) {
        InstallPackage($pkg)
    }
}
elseif ($installation_type -eq "full") {
    foreach ($pkg in $config_full_pkgs) {
        InstallPackage($pkg)
    }
}


# Ripgrep default config
do{
    $ripgrep_config = Read-Host -Prompt 'Do you want create default config for ripgrep [y/n]?'
    $ripgrep_config = $ripgrep_config.ToLower()
} 
while (-not (($ripgrep_config -eq "y") -or ($ripgrep_config -eq "n")))


if ($ripgrep_config -eq "y"){
    Write-Host "Creating default config..."

    New-Item $path_folder -itemType Directory
    New-Item $ripgrep_bat_full_path
    Set-Content $ripgrep_bat_full_path '@echo off
rg -i -B 4 -A 5 -U --glob-case-insensitive %*'

    Write-Host "Setting system variable..."

    if (-not $Env:PATH.Split(";").Contains($path_folder)){
        $path_append = ";" + $path_folder
        [Environment]::SetEnvironmentVariable("PATH", $Env:PATH + $path_append, [EnvironmentVariableTarget]::Machine)
    }

}

Pause
