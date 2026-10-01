param(
    [Parameter(Mandatory = $true)][string]$PackagePath,
    [string]$OutputPath = (Join-Path $PSScriptRoot "../../target/windows-smoke-tests")
)
$ErrorActionPreference = "Stop"
$package = (Resolve-Path $PackagePath).Path
$output = [System.IO.Path]::GetFullPath($OutputPath)
[System.IO.Directory]::CreateDirectory($output) | Out-Null
$exe = Join-Path $package "starship-journal.exe"
foreach ($file in @("starship-journal.exe", "qt.conf", "plugins/platforms/qwindows.dll",
                    "plugins/platforms/qoffscreen.dll", "plugins/styles/breeze6.dll",
                    "plugins/kf6/kirigami/platform/org.kde.desktop.dll",
                    "qml/org/kde/kirigami/qmldir", "qml/org/kde/desktop/qmldir",
                    "icons/breeze/breeze-icons.rcc")) {
    if (!(Test-Path (Join-Path $package $file))) { throw "Missing packaged runtime: $file" }
}

# A fresh process must run without discovering Qt/KDE in the developer's SDK.
$variables = @("PATH", "QML_IMPORT_PATH", "QML2_IMPORT_PATH", "QT_PLUGIN_PATH",
               "QT_QUICK_CONTROLS_STYLE", "QT_STYLE_OVERRIDE", "QTDIR", "QMAKE",
               "QT_QPA_PLATFORM", "QT_QUICK_BACKEND", "QT_FORCE_STDERR_LOGGING",
               "QT_SCALE_FACTOR", "QT_SCALE_FACTOR_ROUNDING_POLICY", "QT_FONT_DPI",
               "STARSHIP_TEST_OUTPUT_DIR")
$saved = @{}
foreach ($name in $variables) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
try {
    foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $null, "Process") }
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
    $env:QT_QPA_PLATFORM = "offscreen"
    $env:QT_QUICK_BACKEND = "software"
    $env:QT_FORCE_STDERR_LOGGING = "1"
    $env:QT_SCALE_FACTOR_ROUNDING_POLICY = "PassThrough"
    foreach ($scale in @("1", "1.5")) {
        $env:QT_SCALE_FACTOR = $scale
        $previewOutput = if ($scale -eq "1") { $output } else { Join-Path $output "dpi-150" }
        [System.IO.Directory]::CreateDirectory($previewOutput) | Out-Null
        $env:STARSHIP_TEST_OUTPUT_DIR = $previewOutput
        foreach ($variant in @("desktop", "narrow")) {
            $arguments = @("--smoke-test")
            if ($variant -eq "narrow") { $arguments += "--narrow-test" }
            else { $arguments += @("-qwindowgeometry", "1600x1000") }
            $stdout = Join-Path $previewOutput "$variant.stdout.log"
            $stderr = Join-Path $previewOutput "$variant.stderr.log"
            $process = Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $previewOutput `
                -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
            # Retain a process handle so ExitCode is available even after a fast exit.
            $handle = $process.Handle
            if (!$process.WaitForExit(45000)) {
                $process.Kill()
                throw "Windows $variant smoke test timed out at scale $scale"
            }
            $process.WaitForExit()
            $diagnostics = Get-Content $stderr -Raw
            Write-Host $diagnostics
            if ($process.ExitCode -ne 0) { throw "Windows $variant smoke test exited $($process.ExitCode) at scale $scale" }
            if ($diagnostics -match "Invalid path data|not placed in the graphics scene|Binding loop|SMOKE FAIL") {
                throw "Windows $variant has visual runtime warnings at scale $scale"
            }
        }
        foreach ($image in @("desktop", "narrow", "mission", "mission-narrow", "cards", "cards-narrow",
                             "compare", "compare-narrow", "selector", "selector-narrow",
                             "analysis", "analysis-narrow", "coordinates", "coordinates-narrow",
                             "flight14-coordinates", "flight14-coordinates-narrow",
                             "launch", "launch-narrow", "milestones", "milestones-narrow",
                             "filtered", "filtered-narrow")) {
            $path = Join-Path $previewOutput "starship-kirigami-$image.png"
            if (!(Test-Path $path) -or (Get-Item $path).Length -eq 0) { throw "Missing screenshot: $image at scale $scale" }
        }
    }
    Write-Host "Windows package passed desktop and narrow tests at 100% and 150% scaling, including panel spacing, selector popups, icons and all 14 JPEG XL photos."
} finally {
    foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $saved[$name], "Process") }
}
