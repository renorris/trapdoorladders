# Trapdoor Ladder Mod

A Vintage Story logic mod skeleton ready for development.

## Prerequisites

Before building this mod, ensure you have:

1. **.NET 8.0 SDK** (x64 version) installed
2. **Visual Studio Community** or **JetBrains Rider**
3. **Vintage Story** installed
4. **Vintage Story Mod Template** installed:
   ```powershell
   dotnet new install VintageStory.Mod.BasicTemplate
   ```

## Setup Instructions

### 1. Set Environment Variable

Open PowerShell in your Vintage Story installation folder (where `Vintagestory.exe` is located) and run:

```powershell
[Environment]::SetEnvironmentVariable("VINTAGE_STORY", ($pwd.path), "User")
```

This tells the compiler where to find the game's DLLs.

### 2. Open Project

Open `trapdoorladders.csproj` in Visual Studio or Rider.

### 3. Build & Run

**Using the Build Script (Recommended):**
```powershell
# Build Release version
.\build.ps1

# Build Release and create zip package
.\build.ps1 -CreateZip

# Build Debug version
.\build.ps1 -Configuration Debug
```

**Using Visual Studio:**
- **Debug Build:** Press F5 in Visual Studio to build and launch the game with your mod loaded
- **Release Build:** Build in Release mode, then manually copy the `.dll` to your mod folder

The build script will:
1. Clean previous builds
2. Compile the C# project
3. Copy the DLL, modinfo.json, modicon.png, and assets folder to a `dist/` directory
4. Optionally create a zip file for distribution

## Project Structure

```
trapdoorladders/
├── modinfo.json              # Mod metadata and version info
├── modicon.png              # 128x128 icon (create this!)
├── trapdoorladders.csproj   # C# project configuration
├── src/
│   └── TrapdoorLaddersSystem.cs  # Main mod logic
└── assets/
    └── trapdoorladders/     # Asset domain
        ├── blocktypes/      # Block JSON definitions
        ├── itemtypes/       # Item JSON definitions
        ├── textures/        # PNG texture files
        └── shapes/          # JSON model files
```

## Next Steps

1. **Create modicon.png:** Add a 128x128 pixel icon for your mod
2. **Implement Logic:** Edit `src/TrapdoorLaddersSystem.cs` to add your mod functionality
3. **Add Assets:** Place JSON definitions and textures in the `assets/` folder
4. **Test:** Use F5 in Visual Studio to test your mod

## Distribution

**Using the build script:**
```powershell
.\build.ps1 -CreateZip
```

This will create `trapdoorladders-v1.0.0.zip` ready for distribution.

**Manual distribution:**
1. Build in Release mode using the script: `.\build.ps1`
2. Copy the contents of the `dist/` folder to your Vintage Story Mods folder for testing
3. Or zip the `dist/` folder contents and rename to `trapdoorladders-v1.0.0.zip`

## Resources

- [Vintage Story Modding Guide](https://wiki.vintagestory.at/index.php/Modding)
- [Comprehensive Modding Video](https://www.youtube.com/watch?v=bJra9zF4Znk)
- [Vintage Story Mods Forum](https://mods.vintagestory.at/)

