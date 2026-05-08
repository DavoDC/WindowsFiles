# Windows Files

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G31WKOCN)

A collection of utilities, scripts, and registry tweaks for Windows system maintenance, customization, and automation.

## Contents

### Registry Tweaks

Pre-built registry files (.reg) for common Windows customizations:

- **Add_Edit_With_VS_Code.reg** - Adds "Edit with Code" context menu option
- **Add_Open_Command_Window_Here.reg** - Adds command window shortcut to context menu
- **Disable_Internet_Search_in_Windows_Search.reg** - Disables web search in Windows Search
- **Enable_GPU_HW_Acceleration.reg** - Enables GPU hardware acceleration
- **Enable_Old_Photo_Viewer.reg** - Restores Windows Photo Viewer (pre-Windows 10 version)
- **Turn_on_Location_Services.reg** - Enables location services
- **Win11_Enable_Classic_Context_Menu.reg** - Restores classic context menu in Windows 11
- **Win11_Enable_Classic_Explorer_Ribbon.reg** - Restores traditional ribbon UI in File Explorer (Windows 11)
- **Win11_Enable_Login_PW_Revealer.reg** - Shows password characters during login

### Batch Scripts

Automated maintenance and utility scripts:

- **bat_fix_Ethernet.bat** - Repairs Ethernet connectivity issues
- **bat_fix_IP.bat** - Fixes network IP configuration problems
- **bat_toggle_Ethernet.bat** - Toggles Ethernet adapter on/off
- **bat_fix_Explorer.bat** - Resolves File Explorer issues and crashes
- **bat_fix_Services.bat** - Restarts critical Windows services
- **bat_play_All_Music.bat** - Plays all music files in a directory recursively

### PowerShell Scripts

Advanced automation tools with interactive interfaces:

#### Arr_Manager
Manages Sonarr/Radarr/Lidarr (Arr suite) instances - start, stop, and monitor media server applications.

#### FFMPEG_Compress
Video compression utility using FFmpeg. Supports batch processing and various codec presets.

#### Internet_Fixer
Comprehensive network troubleshooting and repair tool for internet connectivity issues.

#### Misc
Utility scripts for general Windows tasks:
- **putFilesInFolders.ps1** - Organizes files into folders
- **deleteEmptyFolders.ps1** - Removes empty directories recursively

#### PhotoAudit
Photo library management and analysis tool.

## Usage

### Applying Registry Tweaks
1. Navigate to the Registry_Tweaks folder
2. Right-click the desired .reg file
3. Select "Merge" to apply the changes
4. Confirm the security prompt

Alternatively, double-click the file and confirm the merge dialog.

### Running Batch Scripts
Most batch scripts require Administrator privileges:
1. Right-click the .bat file
2. Select "Run as administrator"
3. Follow any on-screen prompts

### Running PowerShell Scripts
Most PowerShell tools include a corresponding batch launcher (run_ps_*.bat) for convenience:
1. Right-click the launcher .bat file
2. Select "Run as administrator"

Or run directly in PowerShell (may require execution policy adjustment):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
& 'C:\path\to\script.ps1'
```

## Setup Reference

For comprehensive Windows setup and configuration notes, see the [Windows Setup Guide](https://docs.google.com/document/d/1cEh2TEkaPkvQCwGdlBJIRZQzbWfONlUcsY1TLL94csA).