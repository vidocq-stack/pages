# Vidocq CLI installer — https://vidocq.dev/install.ps1
#
# Downloads the latest released Vidocq CLI distribution from Maven Central
# into %USERPROFILE%\.vidocq\cli and adds it to the user PATH.
#
# Usage:
#   irm https://vidocq.dev/install.ps1 | iex
#   $env:VIDOCQ_VERSION = '0.2.1'; irm https://vidocq.dev/install.ps1 | iex      # pin a version
#   $env:VIDOCQ_VERSION = 'snapshot'; irm https://vidocq.dev/install.ps1 | iex   # latest build of main
$ErrorActionPreference = 'Stop'

$central     = 'https://repo1.maven.org/maven2/io/vidocq/runtime/vidocq-runtime-cli'
# Every build of main publishes its SNAPSHOTs there.
$snapshots   = 'https://central.sonatype.com/repository/maven-snapshots/io/vidocq/runtime/vidocq-runtime-cli'
$installRoot = Join-Path $env:USERPROFILE '.vidocq\cli'

function Say([string]$msg)  { Write-Host "-> $msg" -ForegroundColor Cyan }
function Ok([string]$msg)   { Write-Host "OK $msg" -ForegroundColor Green }
function Fail([string]$msg) { Write-Host "XX $msg" -ForegroundColor Red; exit 1 }

# -- Prerequisites ------------------------------------------------
$java = Get-Command java -ErrorAction SilentlyContinue
if (-not $java) {
    Fail "Java 25+ is required but no 'java' was found. Install Temurin 25 from https://adoptium.net"
}
$versionLine = (& java -version 2>&1 | Select-Object -First 1) -join ''
if ($versionLine -match '"(\d+)') { $javaMajor = [int]$Matches[1] } else { Fail "Could not parse the local Java version." }
if ($javaMajor -lt 25) { Fail "Java 25+ is required (found Java $javaMajor). Install Temurin 25 from https://adoptium.net" }
Ok "Java $javaMajor detected"

# -- Resolve the version ------------------------------------------
if ($env:VIDOCQ_VERSION -eq 'snapshot') {
    Say 'Resolving the latest SNAPSHOT from the Central snapshot repository...'
    [xml]$metadata = (Invoke-WebRequest -UseBasicParsing "$snapshots/maven-metadata.xml").Content
    $version = @($metadata.metadata.versioning.versions.version) |
        Where-Object { $_ -like '*-SNAPSHOT' } |
        Sort-Object { [version]($_ -replace '-SNAPSHOT$', '') } |
        Select-Object -Last 1
    if (-not $version) { Fail 'Could not resolve the latest SNAPSHOT from the snapshot metadata.' }
    Ok "Latest SNAPSHOT: $version"
} elseif ($env:VIDOCQ_VERSION) {
    $version = $env:VIDOCQ_VERSION
    Say "Using pinned version $version"
} else {
    Say 'Resolving the latest release from Maven Central...'
    [xml]$metadata = (Invoke-WebRequest -UseBasicParsing "$central/maven-metadata.xml").Content
    $version = $metadata.metadata.versioning.release
    if (-not $version) { Fail 'Could not resolve the latest release from Central metadata.' }
    Ok "Latest release: $version"
}

# -- Download and unpack ------------------------------------------
$target = Join-Path $installRoot $version
$launcher = Join-Path $target 'bin\vidocq.cmd'
$snapshot = $version -like '*-SNAPSHOT'

if ($snapshot) {
    # A SNAPSHOT zip is stored under a timestamped name and changes with every
    # build of main: always download it again.
    [xml]$versionMetadata = (Invoke-WebRequest -UseBasicParsing "$snapshots/$version/maven-metadata.xml").Content
    $stamp = @($versionMetadata.metadata.versioning.snapshotVersions.snapshotVersion) |
        Where-Object { $_.classifier -eq 'cli' -and $_.extension -eq 'zip' } |
        Select-Object -First 1 -ExpandProperty value
    if (-not $stamp) { Fail "No $version distribution zip in the snapshot metadata." }
    Ok "Build $stamp"
    $distUrl = "$snapshots/$version/vidocq-runtime-cli-$stamp-cli.zip"
} else {
    $distUrl = "$central/$version/vidocq-runtime-cli-$version-cli.zip"
}

if (-not $snapshot -and (Test-Path $launcher)) {
    Ok "Vidocq CLI $version is already installed in $target"
} else {
    $tmpZip = Join-Path ([IO.Path]::GetTempPath()) "vidocq-cli-$version.zip"
    Say "Downloading $distUrl..."
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $distUrl -OutFile $tmpZip
    } catch {
        Fail "Download failed - the $version distribution zip may not be published yet."
    }
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Expand-Archive -Path $tmpZip -DestinationPath $target
    Remove-Item $tmpZip
    Ok "Installed in $target"
}

# -- PATH ----------------------------------------------------------
$binDir = Join-Path $target 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$entries = ($userPath -split ';') | Where-Object { $_ -and ($_ -notlike (Join-Path $installRoot '*')) }
$newPath = ($entries + $binDir) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
Ok "Added $binDir to your user PATH"

Say 'Restart your terminal, then try: vidocq version'
