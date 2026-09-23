# Exporim File-Sync

Exporim File-Sync is a fast, lightweight folder synchronization and backup tool for Windows. It mirrors or two-way syncs folders on a schedule, with optional compression, per-profile include/exclude rules, and a system tray presence for unattended background runs.

This project is a modernized fork of the abandoned [Create Synchronicity](https://github.com/createsoftware/Create-Synchronicity) (last updated 2011), migrated to run on **.NET 10**.

## Features

- Mirror or two-way synchronization between any two folders
- Per-profile scheduling (run at a given time/day, or catch up if a scheduled run was missed)
- Include/exclude rules by file extension, filename, folder name, or regex
- Optional GZip/BZip2 compression of synced files
- Runs quietly in the system tray; can be driven entirely from the command line for unattended/scheduled use
- 21 language translations
- Portable or installed mode (writes its config next to the executable if that folder is writable, otherwise under `%APPDATA%`)

## Requirements

- Windows (the app is Windows-only; it uses WinForms and the Windows registry for autostart)
- No separate .NET runtime install needed — releases are published self-contained

## Installing

Download the latest installer from the [Releases](https://github.com/gmedina-exporim/Exporim-File-Sync/releases) page and run it. It installs to `Program Files`, adds Start Menu shortcuts, and registers an uninstaller.

## Building from source

Requires the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0).

```
dotnet build "Exporim File-Sync.sln" -c Release
```

To produce the self-contained Windows build used for releases:

```
dotnet publish "Exporim File-Sync\Exporim File-Sync.vbproj" -c Release -r win-x64 --self-contained true -o publish
```

`package.bat` runs a local build + installer (no upload). `release.bat <version>` builds, publishes, packages the NSIS installer, tags the repo, and creates a GitHub release with `gh` — see `release.bat /?` for details. Building the installer additionally requires [NSIS](https://nsis.sourceforge.io/).

## Command-line usage

```
Exporim File-Sync.exe /help
Exporim File-Sync.exe /run "Profile1|Profile2"   Run one or more profiles immediately, by name
Exporim File-Sync.exe /scheduler                 Run in background scheduler mode
Exporim File-Sync.exe /quiet                     Suppress prompts / run minimized to tray
Exporim File-Sync.exe /silent                     Suppress prompts and enable app-event logging
Exporim File-Sync.exe /preview                   Show a preview of changes before syncing
Exporim File-Sync.exe /log                       Force logging
Exporim File-Sync.exe /noupdates                 Skip the startup update check
Exporim File-Sync.exe /nostop                    Keep the sync window open after finishing
```

Profiles are stored as `.sync` files, and program-wide settings as `mainconfig.ini`, both under the app's config folder (shown in the About box, or via `/help`).

## License

GPLv3 or later — see [COPYING](Exporim%20File-Sync/COPYING).

## Credits

Originally created by Clément Pit-Claudel as [Create Synchronicity](https://github.com/createsoftware/Create-Synchronicity). This fork continues it under a new name and a modern .NET 10 codebase.
