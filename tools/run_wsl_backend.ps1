param(
    [Parameter(Mandatory = $true)][string]$Distro,
    [Parameter(Mandatory = $true)][string]$Python,
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$BackendEntry,
    [Parameter(Mandatory = $true)][string]$InputCsv,
    [Parameter(Mandatory = $true)][string]$InputMeta,
    [Parameter(Mandatory = $true)][string]$OutputCsv,
    [Parameter(Mandatory = $true)][string]$OutputMeta
)

function Convert-ToWslPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if ($PathValue -match '^[\\]{2}wsl(?:\.localhost)?\\[^\\]+\\(.*)$') {
        return '/' + ($Matches[1] -replace '\\', '/')
    }

    if ($PathValue -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $suffix = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$suffix"
    }

    return ($PathValue -replace '\\', '/')
}

function Quote-BashArg {
    param(
        [Parameter(Mandatory = $true)][string]$Value
    )

    return "'" + ($Value -replace "'", "'""'""'") + "'"
}

$repoRootWsl = Convert-ToWslPath -PathValue $RepoRoot
$backendEntryWsl = Convert-ToWslPath -PathValue $BackendEntry
$inputCsvWsl = Convert-ToWslPath -PathValue $InputCsv
$inputMetaWsl = Convert-ToWslPath -PathValue $InputMeta
$outputCsvWsl = Convert-ToWslPath -PathValue $OutputCsv
$outputMetaWsl = Convert-ToWslPath -PathValue $OutputMeta

$bashCommand = "cd $(Quote-BashArg $repoRootWsl) && $(Quote-BashArg $Python) $(Quote-BashArg $backendEntryWsl) --input-csv $(Quote-BashArg $inputCsvWsl) --input-meta $(Quote-BashArg $inputMetaWsl) --output-csv $(Quote-BashArg $outputCsvWsl) --output-meta $(Quote-BashArg $outputMetaWsl)"

& wsl.exe -d $Distro bash -lc $bashCommand
exit $LASTEXITCODE
