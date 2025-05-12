function Safe-Import-Module
{
    param (
        [string]$module
    )

    if (Get-Module -ListAvailable -Name $module)
    {
        Import-Module -Name $module
    }

}


function Install-Modules
{
    $modules = @(
        "Terminal-Icons"
    )

    foreach ($module in $modules)
    {
        if (-not (Get-Module -ListAvailable -Name $module))
        {
            Write-Host "$module is not installed. Installing..."
            try
            {
                Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
                Write-Host "$module installed successfully."
            } catch
            {
                Write-Warning "Failed to install $module"
            }
        } else
        {
            Write-Host "$module is installed already"
        }
    }
}

Set-Location $env:USERPROFILE

Safe-Import-Module("Terminal-Icons")

function prompt
{
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf

    $host.ui.RawUI.WindowTitle = "theunrealtarik"

    Write-Host("→ ") -ForegroundColor Green -NoNewLine
    Write-Host("$CmdPromptCurrentFolder") -ForegroundColor Cyan -NoNewLine
    Write-Host("") -ForegroundColor White -NoNewLine
    return " "
}

