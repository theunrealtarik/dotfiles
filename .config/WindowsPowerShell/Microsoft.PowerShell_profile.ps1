# oh-my-posh init pwsh --config "~/.themes/default.json" | Invoke-Expression
Set-Location $env:USERPROFILE

function prompt {
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf

    $host.ui.RawUI.WindowTitle = "txreqb2w"

    Write-Host("-> ") -ForegroundColor Green -NoNewLine
    Write-Host("$CmdPromptCurrentFolder") -ForegroundColor Cyan -NoNewLine
    Write-Host("") -ForegroundColor White -NoNewLine
    return " "
}

