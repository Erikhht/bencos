;RealAnime NSIS Installer
;NSIS Modern User Interface version 1.67
;Based on codes by Joost Verburg

!define SOURCE_PATH ".\out" ;Define where to find files
!define ENG_NAME "BENCOS" ;Define the product name

;--------------------------------
;Include Modern UI

  !include "MUI.nsh"
;--------------------------------
;Include Macros

; ################################################################
; appends \ to the path if missing
; example: !insertmacro GetCleanDir "c:\blabla"
; Pop $0 => "c:\blabla\"
!macro GetCleanDir INPUTDIR
  ; ATTENTION: USE ON YOUR OWN RISK!
  ; Please report bugs here: http://stefan.bertels.org/
  !define Index_GetCleanDir 'GetCleanDir_Line${__LINE__}'
  Push $R0
  Push $R1
  StrCpy $R0 "${INPUTDIR}"
  StrCmp $R0 "" ${Index_GetCleanDir}-finish
  StrCpy $R1 "$R0" "" -1
  StrCmp "$R1" "\" ${Index_GetCleanDir}-finish
  StrCpy $R0 "$R0\"
${Index_GetCleanDir}-finish:
  Pop $R1
  Exch $R0
  !undef Index_GetCleanDir
!macroend
 
; ################################################################
; similar to "RMDIR /r DIRECTORY", but does not remove DIRECTORY itself
; example: !insertmacro RemoveFilesAndSubDirs "$INSTDIR"
!macro RemoveFilesAndSubDirs DIRECTORY
  ; ATTENTION: USE ON YOUR OWN RISK!
  ; Please report bugs here: http://stefan.bertels.org/
  !define Index_RemoveFilesAndSubDirs 'RemoveFilesAndSubDirs_${__LINE__}'
 
  Push $R0
  Push $R1
  Push $R2
 
  !insertmacro GetCleanDir "${DIRECTORY}"
  Pop $R2
  FindFirst $R0 $R1 "$R2*.*"
${Index_RemoveFilesAndSubDirs}-loop:
  StrCmp $R1 "" ${Index_RemoveFilesAndSubDirs}-done
  StrCmp $R1 "." ${Index_RemoveFilesAndSubDirs}-next
  StrCmp $R1 ".." ${Index_RemoveFilesAndSubDirs}-next
  IfFileExists "$R2$R1\*.*" ${Index_RemoveFilesAndSubDirs}-directory
  ; file
  Delete "$R2$R1"
  goto ${Index_RemoveFilesAndSubDirs}-next
${Index_RemoveFilesAndSubDirs}-directory:
  ; directory
  RMDir /r "$R2$R1"
${Index_RemoveFilesAndSubDirs}-next:
  FindNext $R0 $R1
  Goto ${Index_RemoveFilesAndSubDirs}-loop
${Index_RemoveFilesAndSubDirs}-done:
  FindClose $R0
 
  Pop $R2
  Pop $R1
  Pop $R0
  !undef Index_RemoveFilesAndSubDirs
!macroend

;--------------------------------
;Configuration

  ;General
  Name "${ENG_NAME}"
  OutFile "BENCOS_20110000.exe"
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

  !insertmacro RemoveFilesAndSubDirs "$INSTDIR"
  ; this will empty that directory (but not delete it)

  SetOutPath "$INSTDIR"
  
  ; Base
  FILE "${SOURCE_PATH}\bencos.exe"

  ; Video
  SetOutPath "$INSTDIR\ffmpeg_win32"
  FILE /r /x .svn "${SOURCE_PATH}\ffmpeg_win32\*.*"
  SetOutPath "$INSTDIR\ffmpeg_win64"
  FILE /r /x .svn "${SOURCE_PATH}\ffmpeg_win64\*.*"
  SetOutPath "$INSTDIR"

  ; Audio
  ;FILE "${SOURCE_PATH}\neroAacEnc.exe"
  FILE "${SOURCE_PATH}\enhAacPlusEnc.exe"
  FILE "${SOURCE_PATH}\ct-libisomedia.dll"
  FILE "${SOURCE_PATH}\oggenc2.exe"
  FILE "${SOURCE_PATH}\faac.exe"
  SetOutPath "$INSTDIR\sox"
  FILE /r /x .svn "${SOURCE_PATH}\sox\*.*"
  SetOutPath "$INSTDIR"

  ; Container
  FILE "${SOURCE_PATH}\MP4Box.exe" 
  SetOutPath "$INSTDIR\mkvtoolnix"
  FILE /r /x .svn "${SOURCE_PATH}\mkvtoolnix\*.*"

  ;Store install folder
  WriteRegStr HKCU "Software\Bencos" "" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro RemoveFilesAndSubDirs "$SMPROGRAMS\$STARTMENU_FOLDER"
  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Bencos

    ; clear
    
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Bencos.lnk" "$INSTDIR\bencos.exe"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\link to Detritus Software.lnk"  "http://www.detritus.qc.ca"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\link to Bencos on Google Code.lnk"  "http://code.google.com/p/bencos/"
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
  !insertmacro RemoveFilesAndSubDirs "$INSTDIR"
  RMDir "$INSTDIR"
  
  !insertmacro MUI_STARTMENU_GETFOLDER Bencos $MUI_TEMP
  
  !insertmacro RemoveFilesAndSubDirs "$SMPROGRAMS\$MUI_TEMP"
  
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

