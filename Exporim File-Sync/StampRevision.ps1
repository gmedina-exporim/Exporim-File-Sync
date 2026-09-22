param(
    [string]$ProjectDir
)

$templatePath = Join-Path $ProjectDir "Revision.template.vb"
$outputPath = Join-Path $ProjectDir "Revision.vb"

$revision = 0
try {
    $gitOutput = git -C $ProjectDir rev-list --count HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitOutput) {
        $revision = [int]$gitOutput.Trim()
    }
} catch {
    $revision = 0
}

(Get-Content -Raw $templatePath) -replace '\$WCREV\$', $revision | Set-Content -NoNewline $outputPath
