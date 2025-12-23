# Build script for Trapdoor Ladders mod
# This script builds the mod and packages it for Vintage Story distribution

param(
    [string]$Configuration = "Release",
    [switch]$CreateZip = $false,
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"

# Get mod info from modinfo.json
$modInfoPath = "modinfo.json"
if (-not (Test-Path $modInfoPath)) {
    Write-Error "modinfo.json not found!"
    exit 1
}

$modInfo = Get-Content $modInfoPath | ConvertFrom-Json
$modId = $modInfo.modid
$version = $modInfo.version

Write-Host "Building $modId v$version..." -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Gray

# Determine Vintage Story installation path
if (-not $env:VINTAGE_STORY) {
    # Try common default installation locations
    $defaultPaths = @(
        "$Env:AppData\Vintagestory",  # Default non-Steam installation
        "$Env:LOCALAPPDATA\Programs\Vintagestory",  # Alternative location
        "$Env:ProgramFiles\Vintagestory",  # Program Files
        "${Env:ProgramFiles(x86)}\Vintagestory",  # Program Files (x86)
        "$Env:USERPROFILE\AppData\Roaming\Vintagestory"  # Explicit user path
    )
    
    # Also check Steam common locations
    $steamPaths = @(
        "$Env:ProgramFiles\Steam\steamapps\common\Vintagestory",
        "${Env:ProgramFiles(x86)}\Steam\steamapps\common\Vintagestory",
        "$Env:USERPROFILE\Steam\steamapps\common\Vintagestory"
    )
    
    $allPaths = $defaultPaths + $steamPaths
    $foundPath = $null
    
    foreach ($path in $allPaths) {
        if (Test-Path $path -PathType Container) {
            # Verify it's actually Vintage Story by checking for Vintagestory.exe or VintagestoryAPI.dll
            if ((Test-Path (Join-Path $path "Vintagestory.exe")) -or (Test-Path (Join-Path $path "VintagestoryAPI.dll"))) {
                $foundPath = $path
                break
            }
        }
    }
    
    if ($foundPath) {
        $env:VINTAGE_STORY = $foundPath
        Write-Host "Auto-detected Vintage Story installation: $foundPath" -ForegroundColor Green
    } else {
        Write-Warning "VINTAGE_STORY environment variable is not set and no default installation found!"
        Write-Warning "Searched locations:"
        foreach ($path in $allPaths) {
            Write-Host "  - $path" -ForegroundColor Gray
        }
        Write-Warning "Set it with: [Environment]::SetEnvironmentVariable('VINTAGE_STORY', 'C:\Path\To\VintageStory', 'User')"
        Write-Warning "Or set it for this session: `$env:VINTAGE_STORY = 'C:\Path\To\VintageStory'"
    }
} else {
    Write-Host "Using VINTAGE_STORY: $env:VINTAGE_STORY" -ForegroundColor Gray
}

# Clean previous build
Write-Host "`nCleaning previous build..." -ForegroundColor Yellow
if (Test-Path "bin") {
    Remove-Item -Path "bin" -Recurse -Force
}
if (Test-Path "obj") {
    Remove-Item -Path "obj" -Recurse -Force
}

# Build the project
Write-Host "`nBuilding project..." -ForegroundColor Yellow
dotnet build trapdoorladders.csproj -c $Configuration --no-incremental

if ($LASTEXITCODE -ne 0 -or -not $?) {
    Write-Error "Build failed! Check the error messages above."
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

# Determine output paths
$buildOutputPath = "bin\$Configuration"
$dllName = "trapdoorladders.dll"

# Check if DLL was created
$dllPath = Join-Path $buildOutputPath $dllName
if (-not (Test-Path $dllPath)) {
    Write-Error "DLL not found at $dllPath"
    Write-Host "Looking for DLL files in $buildOutputPath..." -ForegroundColor Yellow
    Get-ChildItem -Path $buildOutputPath -Filter "*.dll" | ForEach-Object {
        Write-Host "  Found: $($_.Name)" -ForegroundColor Gray
    }
    exit 1
}

# Create distribution directory
Write-Host "`nCreating distribution package..." -ForegroundColor Yellow
if (Test-Path $OutputDir) {
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy DLL to mod root
Write-Host "  Copying DLL..." -ForegroundColor Gray
Copy-Item -Path $dllPath -Destination (Join-Path $OutputDir $dllName) -Force

# Copy modinfo.json
Write-Host "  Copying modinfo.json..." -ForegroundColor Gray
Copy-Item -Path $modInfoPath -Destination (Join-Path $OutputDir "modinfo.json") -Force

# Copy modicon.png if it exists
if (Test-Path "modicon.png") {
    Write-Host "  Copying modicon.png..." -ForegroundColor Gray
    Copy-Item -Path "modicon.png" -Destination (Join-Path $OutputDir "modicon.png") -Force
} else {
    Write-Warning "  modicon.png not found, skipping..."
}

# Copy assets folder if it exists
if (Test-Path "assets") {
    Write-Host "  Copying assets folder..." -ForegroundColor Gray
    Copy-Item -Path "assets" -Destination (Join-Path $OutputDir "assets") -Recurse -Force
}

# Copy any additional files that might be needed
$additionalFiles = @("README.md")
foreach ($file in $additionalFiles) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination (Join-Path $OutputDir $file) -Force
    }
}

Write-Host "`nDistribution package created in: $OutputDir" -ForegroundColor Green

# Create zip file if requested
if ($CreateZip) {
    $zipName = "$modId-v$version.zip"
    $zipPath = Join-Path (Get-Location) $zipName
    
    Write-Host "`nCreating zip archive: $zipName..." -ForegroundColor Yellow
    
    # Remove existing zip if it exists
    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }
    
    # Create zip file
    Compress-Archive -Path "$OutputDir\*" -DestinationPath $zipPath -Force
    
    Write-Host "Zip archive created: $zipPath" -ForegroundColor Green
    Write-Host "`nMod is ready for distribution!" -ForegroundColor Cyan
    Write-Host "  Folder: $OutputDir" -ForegroundColor Gray
    Write-Host "  Zip: $zipName" -ForegroundColor Gray
} else {
    Write-Host "`nMod is ready for testing!" -ForegroundColor Cyan
    Write-Host "  Copy the contents of '$OutputDir' to your Vintage Story Mods folder" -ForegroundColor Gray
    Write-Host "  Or run with -CreateZip to generate a distribution zip file" -ForegroundColor Gray
}

Write-Host "`nBuild complete!" -ForegroundColor Green

