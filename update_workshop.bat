@echo off
REM update_workshop.bat - Upload changes to Steam Workshop using workshop.vdf

REM Set path to SteamCMD
set STEAMCMD_PATH="steamcmd"

REM Set path to workshop.vdf
set VDF_PATH="E:\_PORTABLE\Steam\steamapps\common\GarrysMod\garrysmod\addons\source_party_content_3276706719\workshop.vdf"

REM Set path to fastgmad
set FASTGMAD_PATH="fastgmad"

REM Set script folder path
set SCRIPT_PATH="E:\_PORTABLE\Steam\steamapps\common\GarrysMod\garrysmod\addons\source_party_content_3276706719"

REM Create GMA file using fastgmad
%FASTGMAD_PATH% create -folder %SCRIPT_PATH% -out workshop.gma -warninvalid

REM Prompt for Steam username
set /p STEAM_USER=Enter your Steam username: 

REM Prompt for Steam password (input will be visible)
set /p STEAM_PASS=Enter your Steam password: 

REM Run SteamCMD to upload the workshop item
%STEAMCMD_PATH% +login %STEAM_USER% %STEAM_PASS% +workshop_build_item %VDF_PATH% +quit

pause