
# Start as admin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Maximized
    exit;
}



#region Configs & variables
$configs = @('core', 'gui', 'dev', 'full')

$config_core_pkgs = @()
$config_gui_pkgs = $config_core_pkgs + @('chocolateygui')
$config_dev_pkgs = $config_gui_pkgs + @('ripgrep', 'dotnet-6.0-sdk', 'git', 'gitkraken', 'visualstudio2022community', 'sql-server-management-studio', 'vscode', 'postman', 'nodejs', 'python', 'docker-desktop')
$config_full_pkgs = $config_dev_pkgs + @('adobereader', 'googledrive', 'lightshot', 'vlc', 'winrar', 'teamspeak', 'discord', 'steam-client', 'firefox', 'ubisoft-connect')

$path_folder = "C:\path"

$ripgrep_bat = "ripg.bat"
$ripgrep_bat_full_path = "$path_folder\$ripgrep_bat"
$ripgrep_bat_content = '@echo off
    rg -i -B 4 -A 5 -U --glob-case-insensitive %*'

$temp_bat = "temp.bat"
$temp_bat_full_path = "$path_folder\$temp_bat"
$temp_bat_content = '@echo off
if not exist C:\Temp\ (
    cd C:\
    mkdir Temp
)

cd C:\Temp'

$gitignore_bat = "gi.bat"
$gitignore_bat_full_path = "$path_folder\$gitignore_bat"
$gitignore_bat_content = ':: Creates .NET gitignore
@echo off

dotnet new gitignore
if  errorlevel 1 goto ERROR
goto END

:ERROR
pause

:END
exit'

$hosts_file = "C:\Windows\System32\Drivers\etc\hosts"

$wifi_ip = "192.168.0.1"
$wifi_alias = "wifi.local"

$nas_ip = "192.168.0.194"
$nas_alias = "nas.local"
#endregion


#region Functions
function CreatePathFolder {

    $exists = Test-Path -Path $path_folder

    if (-not $exists){
        Write-Host "Creating path folder [$path_folder]" -ForegroundColor Gray
        New-Item $path_folder -itemType Directory
    }

    if (-not $Env:PATH.Split(";").Contains($path_folder)){
        Write-Host "Setting system variable [PATH]" -ForegroundColor Gray
        $path_append = ";" + $path_folder
        [Environment]::SetEnvironmentVariable("PATH", $Env:PATH + $path_append, [EnvironmentVariableTarget]::Machine)
    }
}

function InstallCore { # Install chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
}

function InstallPackage {
    param ($pkg)
    
    choco install $pkg -y
}

function InstallPackages {
    param ($installation_type)
    
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
}

function VerifyRgInstalled {
    $choco_installed_pkgs = choco list --local-only

    foreach ($pkg in $choco_installed_pkgs) {
        if ($pkg.ToString().StartsWith("ripgrep") -eq $true){
            return $true
        }
    }

    return $false
}

function CreateRipGrepConfig {
    
    CreatePathFolder
        
    Write-Host "Creating default config [$ripgrep_bat_full_path]" -ForegroundColor Gray
    New-Item $ripgrep_bat_full_path
    
    Write-Host $(Write-Host "Config:" -ForegroundColor Gray) + $(Write-Host $ripgrep_bat_content -ForegroundColor Magenta; Write-Host "")
    
    Set-Content $ripgrep_bat_full_path $ripgrep_bat_content
}

function CreateTempCmdVariable {

    CreatePathFolder
    
    Write-Host "Creating temp cmd variable [$temp_bat_full_path]" -ForegroundColor Gray
    New-Item $temp_bat_full_path
    
    Write-Host $(Write-Host "Config:" -ForegroundColor Gray) + $(Write-Host $temp_bat_content -ForegroundColor Magenta; Write-Host "")
    
    Set-Content $temp_bat_full_path $temp_bat_content
}

function CreateGitignoreCmdVariable {

    CreatePathFolder
    
    Write-Host "Creating gitignore cmd variable [$gitignore_bat_full_path]" -ForegroundColor Gray
    New-Item $gitignore_bat_full_path
    
    Write-Host $(Write-Host "Config:" -ForegroundColor Gray) + $(Write-Host $gitignore_bat_content -ForegroundColor Magenta; Write-Host "")
    
    Set-Content $gitignore_bat_full_path $gitignore_bat_content
}

function EnableSSMSDarkMode {
    
    # TODO: make version non-dependend
    $filePath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.pkgundef"
    $themeKey = '[$RootKey$\Themes\{1ded0138-47ce-435e-84ef-9ec1f439b749}]'
    $fileExists = Test-Path -Path $filePath -PathType Leaf

    if ($fileExists){
        Write-Host "Enabling SSMS dark mode..." -ForegroundColor Gray
        (Get-Content $filePath).Replace($themeKey, "// $themeKey") | Out-File $filePath
    }
}

function SetNasAlias {
    
    Write-Host "Setting '$nas_alias' alias for NAS [$nas_ip]..." -ForegroundColor Gray

    $file = Get-Content -Path $hosts_file
    $value = "$nas_ip		$nas_alias"
    $contains = $false

    foreach ($row in $file) {
        if ($row.Contains($value)){
            $contains = $true
            break
        }
    }

    if (-Not $contains){
        $value | Out-File -FilePath $hosts_file -Encoding ascii -Append
    }
}

function SetWifiAlias {
    
    Write-Host "Setting '$wifi_alias' alias for local wifi router [$wifi_ip]..." -ForegroundColor Gray

    $file = Get-Content -Path $hosts_file
    $value = "$wifi_ip			$wifi_alias"
    $contains = $false

    foreach ($row in $file) {
        if ($row.Contains($value)){
            $contains = $true
            break
        }
    }

    if (-Not $contains){
        $value | Out-File -FilePath $hosts_file -Encoding ascii -Append
    }
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

function Done {
    Write-Host $(Write-Host; Write-Host "=== Done ===" -Foreground Green; Write-Host; Pause)
}
#endregion


# Instalation type
do {
    $installation_type = $(Write-Host 'Enter installation type' -NoNewline) + $(Write-Host $(' [' + $($configs -join ', ') + ']') -ForegroundColor Yellow -NoNewLine) + $(Write-Host ' ("?" for help): ' -ForegroundColor Green -NoNewLine; Read-Host)
    $installation_type = $installation_type.ToLower()

    if ($installation_type -eq "?"){
        ShowHelp
    }
} 
while (-not $configs.Contains($installation_type))


# Install chocolatey
InstallCore

# Install packages
InstallPackages($installation_type)

# Ripgrep default config
if (VerifyRgInstalled){

    do{
        $ripgrep_config = $(Write-Host) + $(Write-Host "Do you want create default config for ripgrep?" -NoNewline) + $(Write-Host " [y/n]: " -ForegroundColor Yellow -NoNewLine; Read-Host)
        $ripgrep_config = $ripgrep_config.ToLower()
    } 
    while (-not (($ripgrep_config -eq "y") -or ($ripgrep_config -eq "n")))


    if ($ripgrep_config -eq "y"){
        CreateRipGrepConfig
    }
}


# Hosts file
SetNasAlias
SetWifiAlias

# SSMS settings
EnableSSMSDarkMode

# Cmd variables
CreateTempCmdVariable
CreateGitignoreCmdVariable


# ================ DONE ================
Done
