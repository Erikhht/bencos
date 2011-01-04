;RealAnime NSIS Installer
;NSIS Modern User Interface version 1.67
;Based on codes by Joost Verburg

!define SOURCE_PATH "C:\Users\Sirber\Documents\My Dropbox\prog\bencos\out" ;Define where to find files
!define ENG_NAME "BENCOS" ;Define the product name

;--------------------------------
;Include Modern UI

  !include "MUI.nsh"

;--------------------------------
;Configuration

  ;General
  Name "${ENG_NAME}"
  OutFile "BENCOS_20100000.exe"
  SetCompressor /SOLID /FINAL lzma
  SetCompressorDictSize 128

  ;Folder selection page
  InstallDir "$PROGRAMFILES\Bencos"
  ;InstallDir "$PROGRAMFILES64\Bencos"
  
  ;Get install folder from registry if available
  InstallDirRegKey HKCU "Software\Bencos" ""

;--------------------------------
;Variables

  Var MUI_TEMP
  Var STARTMENU_FOLDER
  
;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "${SOURCE_PATH}\gpl.txt"
  ;!insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\bencos" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  !insertmacro MUI_PAGE_STARTMENU Bencos $STARTMENU_FOLDER
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Bencos" SecBC

  SetOutPath "$INSTDIR"
  
  ; Base
  FILE "${SOURCE_PATH}\bencos.exe"
  FILE "${SOURCE_PATH}\ffprobe.exe"

  ; Video
  FILE "${SOURCE_PATH}\ffmpeg.exe"
  SetOutPath "$INSTDIR\presets"
  FILE /r /x .svn "${SOURCE_PATH}\presets\*.*"
  SetOutPath "$INSTDIR"

  ; Audio
  ;FILE "${SOURCE_PATH}\neroAacEnc.exe"
  FILE "${SOURCE_PATH}\enhAacPlusEnc.exe"
  FILE "${SOURCE_PATH}\ct-libisomedia.dll"
  FILE "${SOURCE_PATH}\oggenc2.exe"
  FILE "${SOURCE_PATH}\faac.exe"

  ; Container
  FILE "${SOURCE_PATH}\MP4Box.exe" 
  SetOutPath "$INSTDIR\mkvtoolnix"
  FILE /r /x .svn "${SOURCE_PATH}\mkvtoolnix\*.*"

  ;Store install folder
  WriteRegStr HKCU "Software\Bencos" "" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Bencos
    
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Bencos.lnk" "$INSTDIR\bencos.exe"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\MKV Merge.lnk" "$INSTDIR\mkv\mmg.exe"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Homepage.lnk"  "http://www.detritus.qc.ca"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

;--------------------------------
;Descriptions

  LangString DESC_SecBC ${LANG_ENGLISH} "${ENG_NAME}"

  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBC} $(DESC_SecBC)    
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ; Removing old BENCOS
  Delete "$INSTDIR\mkv\*.*"
  RMDir "$INSTDIR\mkv\"
  Delete "$INSTDIR\*.*"
  
  !insertmacro MUI_STARTMENU_GETFOLDER Bencos $MUI_TEMP
  
  Delete "$SMPROGRAMS\$MUI_TEMP\Bencos.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\MKV Merge.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Homepage.lnk"
  
  ;Delete empty start menu parent diretories
  StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"
 
  startMenuDeleteLoop:
    RMDir $MUI_TEMP
    GetFullPathName $MUI_TEMP "$MUI_TEMP\.."
    
    IfErrors startMenuDeleteLoopDone
  
    StrCmp $MUI_TEMP $SMPROGRAMS startMenuDeleteLoopDone startMenuDeleteLoop
  startMenuDeleteLoopDone:

  DeleteRegKey /ifempty HKCU "Software\Bencos"

SectionEnd