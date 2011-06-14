unit umain;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Grids, Process, Buttons, Menus, ExtCtrls, uinfo, sqlite3conn,
  fileutil, strutils;

type
  InfoTypeAudio = record
                track:String;        // Track number in source
                lang:String;         // Language in source ('' if not defined).
                is51:boolean;        // Audio is 5.1
                indexCodec:integer;  // Codec index.
                indexBit:integer;    // Quality index.
  end;
  InfoTypeSubtitle = record
                   track:String;     // Track number in source
                   lang:String       // Language in source ('' if not defined).
  end;
  InfoArrayAudio = Array[0..9] of InfoTypeAudio;
  InfoArraySubtitle = Array[0..9] of InfoTypeSubtitle;
  StrArray = Array[0..9] of string;
  { Tfmain }
  Tfmain = class(TForm)
    Button1: TButton;
    cboACodec: TComboBox;
    cboALang: TComboBox;
    cboContainer: TComboBox;
    cboSLang: TComboBox;
    cboAQuality: TComboBox;
    cboVCodecProfile: TComboBox;
    cboVCodecPreset: TComboBox;
    cboVCodecTune: TComboBox;
    chkFNormAudio: TCheckBox;
    chkFResize: TCheckBox;
    chkFRatio: TCheckBox;
    cboVType: TComboBox;
    cboVCodec2: TComboBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    MainMenu1: TMainMenu;
    chkForceMKV: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    mPauseResume: TMenuItem;
    mStart: TMenuItem;
    mStop: TMenuItem;
    Home: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    StatusBar1: TStatusBar;
    txtFRatio: TEdit;
    txtFResize: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label15: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    lstFiles: TStringGrid;
    lstLog: TListBox;
    SpeedButton2: TSpeedButton;
    SysTray: TTrayIcon;
    FileListMenu: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuInfo: TMenuItem;
    mnuResetStatus: TMenuItem;
    mnuRemove: TMenuItem;
    mnuRemoveFinished: TMenuItem;
    mnuRemoveAll: TMenuItem;
    mnuAdd: TMenuItem;
    OpenDialog1: TOpenDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    txtOutput: TEdit;
    txtVBitrate: TEdit;
    procedure btnStartClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure cboACodecChange(Sender: TObject);
    procedure cboVCodec2Change(Sender: TObject);
    procedure cboVCodecPresetChange(Sender: TObject);
    procedure cboVTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure HomeClick(Sender: TObject);
    procedure mPauseResumeClick(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure mStartClick(Sender: TObject);
    procedure mStopClick(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure mnuInfoClick(Sender: TObject);
    procedure mnuRemoveClick(Sender: TObject);
    procedure mnuAddClick(Sender: TObject);
    procedure mnuRemoveAllClick(Sender: TObject);
    procedure mnuRemoveFinishedClick(Sender: TObject);
    procedure mnuResetStatusClick(Sender: TObject);

    procedure parseExitCode(iExitCode: integer);
    procedure deleteTemp();
  private
    aFiles: TStrings;
    oCli: TProcess;
    {oCliA: TAsyncProcess;}
    bStop, bError: boolean;
    sPath, sTemp: string;
    bNeroAAC: boolean;

    { encoding vars }
    sSource, sOutput, sVideoOut{, sAudioOut, sSubtitleOut}: string;
    sAudioOuts, sSubtitleOuts: StrArray;
    sP: string;
    sV, sV1, sV2: string;
    sExtractAudio, sAND, sCod: StrArray;
    sC: string;
    sExtractSubs: StrArray;
    iFileToEncode: integer;
    iExitCode: integer;

    { from probe }
    // Tracks and languages information
    iaAudio: InfoArrayAudio;
    iaSubtitle: InfoArraySubtitle;
    // Number of audio and subtitles tracks.
    iAudio, iSubtitle: Integer;
    sDuration: string;
    iDuration: integer; // in seconds
    iABitrate: integer;
    iASumBitrates: integer;

    iVBitrate: integer;
    bPause: boolean;

    videoWidth, videoHeight: integer;

    procedure AddFile(sFileName: string);
    procedure parseProbe();
    function posStr(val: string; search: string): LongInt;
    function parseTrackAudio(val: string; all: string): InfoTypeAudio;
    function parseTrackSubtitle(val: string): InfoTypeSubtitle;
    function audioBitRate(indexCodec: integer; indexBit: integer): integer;
    function calculateVideoBitrate():integer;
    { *** Process *** }
    function findSource(): boolean;
    procedure makeCmdLine();
    procedure makeCmdLineMerge();
    procedure makeCmdLineProbe();
    procedure encodeFile_start();
    procedure encodeFile();
    function CliRun(sCmd: string): integer;
  public
    oCliLogs: TStrings;
    function getFileStatus(iFilePos: integer):string;
    procedure setFileStatus(iFilePos: integer; sStatus: string);
    procedure AddLog(sMessage: string);
    procedure AddLogFin(sMessage: string);
  end;



var
  fmain: Tfmain;

const
  sVersion: string = '2011-06-13 dev';
  sLazarus: string = 'Lazarus 0.9.30';
  sTarget: string = 'win32'; // win64 gets detected elsewhere
  iNbCore: integer = 0;

implementation

{ Tfmain }
procedure Tfmain.btnStartClick(Sender: TObject);
begin
    encodeFile_start();
end;

function Tfmain.getFileStatus(iFilePos: integer):string;
begin
  Result := lstFiles.Cells[0, iFilePos];
end;

procedure Tfmain.setFileStatus(iFilePos: integer; sStatus: string);
begin
  lstFiles.Cells[0, iFilePos] := sStatus;
end;

function Tfmain.findSource(): boolean;
var
  bFound, bEncode: boolean;
  iFiles, iCpt: integer;
begin
  Result := False;
  if (aFiles.Count <= 0) then
  begin
    ShowMessage('Nothing to do. Queue is empty!');
    exit;
  end;

  iFiles := lstFiles.RowCount - 1; // Last one always empty
  iFileToEncode := -1;
  bFound := False;
  bEncode := False;
  for iCpt := 1 to iFiles do
  begin
    if (getFileStatus(iCpt) = 'ready') then
      bEncode := True;
    if (getFileStatus(iCpt) = 'stopped') and (bStop = False) then
      bEncode := True;
    if (bEncode) then
    begin
      bFound := True;
      bEncode := False;
      iFileToEncode := iCpt - 1;  // Link with aFiles
      break;
    end;
  end;

  if (bFound) then
  begin
    Result := True;
    sSource := aFiles.Strings[iFileToEncode];
  end;
end;

procedure Tfmain.makeCmdLine();
var
  sAudioOut, sXA, sA, sNA,  sSubtitleOut, sS: string;
  iCount: integer;
begin
  // Video (base)
  sV := sPath + 'ffmpeg_' + sTarget + '/ffmpeg.exe -an -sn -threads ' + IntToStr(iNbCore) + ' -i "' + sSource +
    '" -vb ' + IntToStr(iVBitrate) + 'k';

  // Video (filtering)
  if (chkFResize.Checked = True) then
    sV := sV + ' -s ' + txtFResize.Text;
  if (chkFRatio.Checked = True) then
    sV := sV + ' -aspect ' + txtFRatio.Text;

  // Video (codec)
  case cboVCodec2.ItemIndex of
    0: // x264
    begin
      sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + ' -vcodec libx264 -passlogfile ' + sVideoOut + '.pass';

      // Profile
      case cboVCodecProfile.ItemIndex of
        0: sV := sV + ' -profile baseline';
        1: sV := sV + ' -profile main';
        2: sV := sV + ' -profile high';
        3: sV := sV + ' -profile high10';
      end;

      // Preset
      case cboVCodecPreset.ItemIndex of
        0: sV := sV + ' -preset ultrafast';
        1: sV := sV + ' -preset superfast';
        2: sV := sV + ' -preset veryfast';
        3: sV := sV + ' -preset faster';
        4: sV := sV + ' -preset fast';
        5: sV := sV + ' -preset medium';
        6: sV := sV + ' -preset slow';
        7: sV := sV + ' -preset slower';
        8: sV := sV + ' -preset veryslow';
        9: sV := sV + ' -preset placebo';
      end;

      // Tune
      case cboVCodecTune.ItemIndex of
        0: sV := sV + ' -tune film';
        1: sV := sV + ' -tune animation';
        2: sV := sV + ' -tune grain';
      end;

      sV1 := sV + ' -pass 1';
      sV2 := sV + ' -pass 2';
    end;

    1: // VP8
    begin
      sVideoOut := '"' + sTemp + 'video.webm"';
      sV := sV + ' -vcodec libvpx -keyint_min 8 -g 480 -qmax 63 -passlogfile ' +
        sVideoOut;
      sV1 := sV + ' -pass 1';

      // Preset
      case cboVCodecPreset.ItemIndex of
        0: sV2 := sV + ' -pass 2 -level 300';
        1: sV2 := sV + ' -pass 2 -level 200';
        2: sV2 := sV + ' -pass 2 -level 100';
      end;
    end;
  end;
  sV1 := sV1 + ' -y ' + sVideoOut;
  sV2 := sV2 + ' -y ' + sVideoOut;

  for iCount := 0 to iSubtitle - 1 do
  begin
    // Video (subtitles)
    sSubtitleOut := '"' + sTemp + 'subtitle' + IntToStr(iCount) + '.mkv"';
    sS := sPath + 'ffmpeg_' + sTarget + '/ffmpeg.exe -an -vn -y -i "' + sSource +
      '" -map 0:' + iaSubtitle[iCount].track +' -scodec copy ' + sSubtitleOut;
    if (iaSubtitle[iCount].lang <> '') then
       sS := sS + ' -slang ' + iaSubtitle[iCount].lang
    else
      case cboSLang.ItemIndex of
        1: sS := sS + ' -slang jpn ';
        2: sS := sS + ' -slang eng ';
        3: sS := sS + ' -slang fre ';
        4: sS := sS + ' -slang spa ';
      end;
    sExtractSubs[iCount] := sS;
    sSubtitleOuts[iCount] := sSubtitleOut;
  end;

  for iCount := 0 to iAudio - 1 do
  begin
    // Audio
    // - extraction
    sXA := sPath + 'ffmpeg_' + sTarget + '/ffmpeg.exe -vn -y -i "' + sSource +
        '" -map 0:' + iaAudio[iCount].track + ' -f wav';
    if (iaAudio[iCount].is51 = false) then
      sXA := sXA + ' -ac 2';
    sXA := sXA + ' "' + sTemp + 'audio.wav" ';

    // - normalize and 5.1 downmix (issue #13)
    sNA := sPath + 'sox/sox.exe -S -V ';
    sNA := sNA + '"' + sTemp + 'audio.wav" "' + sTemp + 'audio_sox.wav" ';
    if (iaAudio[iCount].is51) then
      sNA := sNA + 'remix -m 1v0.3254,3v0.2301,5v0.2818,6v0.1627 2v0.3254,3v0.2301,5v-0.1627,6v-0.2818 ';
    if (chkFNormAudio.Checked) then
      sNA := sNA + 'norm';

    // - encoding
    case cboACodec.ItemIndex of
      0: // AAC HE+PS
      begin
        sAudioOut := '"' + sTemp + 'audio' + IntToStr(iCount) + '.mp4"';
        if (bNeroAAC) then
        begin
          sA := sPath + 'neroAacEnc.exe -2pass -hev2 ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '-br 16000 ';
            1: sA := sA + '-br 24000 ';
            2: sA := sA + '-br 32000 ';
            3: sA := sA + '-br 48000 ';
          end;
          sA := sA + '-if "' + sTemp + 'audio.wav" -of ' + sAudioOut;
        end
        else
        begin
          sA := sPath + 'enhAacPlusEnc.exe "' + sTemp + 'audio.wav" ' +
            sAudioOut + ' ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '--cbr 16000 ';
            1: sA := sA + '--cbr 24000 ';
            2: sA := sA + '--cbr 32000 ';
            3: sA := sA + '--cbr 48000 ';
          end;
        end;
      end;

      1: // AAC HE
      begin
        sAudioOut := '"' + sTemp + 'audio' + IntToStr(iCount) + '.mp4"';
        if (bNeroAAC) then
        begin
          sA := sPath + 'neroAacEnc.exe -2pass -he ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '-br 32000 ';
            1: sA := sA + '-br 48000 ';
            2: sA := sA + '-br 64000 ';
          end;
          sA := sA + '-if "' + sTemp + 'audio.wav" -of ' + sAudioOut;
        end
        else
        begin
          sA := sPath + 'enhAacPlusEnc.exe "' + sTemp + 'audio.wav" ' +
            sAudioOut + ' ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '--cbr 32000 --disable-ps';
            1: sA := sA + '--cbr 48000 --disable-ps';
            2: sA := sA + '--cbr 64000 --disable-ps';
          end;
        end;
      end;

      2: // AAC LC
      begin
        sAudioOut := '"' + sTemp + 'audio' + IntToStr(iCount) + '.mp4"';
        if (bNeroAAC) then
        begin
          sA := sPath + 'neroAacEnc.exe -2pass -lc ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '-br 64000 ';
            1: sA := sA + '-br 96000 ';
            2: sA := sA + '-br 128000 ';
            3: sA := sA + '-br 192000 ';
            4: sA := sA + '-br 256000 ';
          end;
          sA := sA + '-if "' + sTemp + 'audio.wav" -of ' + sAudioOut;
        end
        else
        begin
          sA := sPath + 'faac.exe ';
          case cboAQuality.ItemIndex of
            0: sA := sA + '-b 64';
            1: sA := sA + '-b 96';
            2: sA := sA + '-b 128';
            3: sA := sA + '-b 192';
            4: sA := sA + '-b 256';
          end;
          sA := sA + ' -o ' + sAudioOut + '"' + sTemp + 'audio.wav" ';
        end;
      end;

      3: // Vorbis
      begin
        sAudioOut := '"' + sTemp + 'audio' + IntToStr(iCount) + '.ogg"';
        sA := sPath + 'oggenc2.exe -o ' + sAudioOut;
        case cboAQuality.ItemIndex of
          0: sA := sA + ' -q -1';
          1: sA := sA + ' -q 0';
          2: sA := sA + ' -q 2';
          3: sA := sA + ' -q 4';
          4: sA := sA + ' -q 6';
          5: sA := sA + ' -q 8';
        end;
        sA := sA + ' "' + sTemp + 'audio.wav" ';
      end;
    end;
    sExtractAudio[iCount] := sXA;
    sCod[iCount] := sA;
    sAND[iCount] := sNA; // audio normalization
    sAudioOuts[iCount] := sAudioOut;
  end;

  // Output
  sOutput := IncludeTrailingPathDelimiter(txtOutput.Text) + ExtractFileName(sSource);
end;

procedure Tfmain.makeCmdLineProbe();
begin
  // Get temp folder
  sTemp := '/tmp/';
  {$IFDEF WIN32}
  sTemp := GetEnvironmentVariable('TEMP') + '/bencos/';
  {$ENDIF}
  if (DirectoryExists(sTemp) = False) then
    MkDir(sTemp);

  // Probe
  sP := sPath + 'ffmpeg_' + sTarget + '/ffprobe.exe "' + sSource + '"';

  iABitrate := audioBitRate(cboACodec.ItemIndex, cboAQuality.ItemIndex);
end;

function Tfmain.audioBitRate(indexCodec: integer; indexBit: integer): integer;
var
  bitrate: integer;
begin

  // Audio bitrate
  case indexCodec of
    0: // AAC HE+PS
    begin
      case indexBit of
        0: bitrate := 16;
        1: bitrate := 24;
        2: bitrate := 32;
        3: bitrate := 48;
      end;
    end;

    1: // AAC HE
    begin
      case indexBit of
        0: bitrate := 32;
        1: bitrate := 48;
        2: bitrate := 64;
      end;
    end;

    2: // AAC LC
    begin
      case indexBit of
        0: bitrate := 64;
        1: bitrate := 96;
        2: bitrate := 128;
        3: bitrate := 192;
        4: bitrate := 256;
      end;
    end;

    3: // Vorbis
    begin
      case indexBit of
        0: bitrate := 48;
        1: bitrate := 64;
        2: bitrate := 96;
        3: bitrate := 128;
        4: bitrate := 192;
        5: bitrate := 256;
      end;
    end;
  end;
  result := bitrate;
end;

procedure Tfmain.makeCmdLineMerge();
var
  iCount: Integer;
  isMkvResult: boolean; // For only one copy mkv merge code
begin
  isMkvResult := False;
  // Merge
  case cboVCodec2.ItemIndex of
    0: // x264
    begin
      // MP4
      if ((cboContainer.ItemIndex = 1) and ((not chkForceMKV.Checked) or (iSubtitle = 0))) then // MP4
      begin
	    sOutput := ChangeFileExt(sOutput, '.mp4');
	    sC := sPath + 'MP4Box.exe -new "' + sOutput +
	       '" -add ' + sVideoOut;
        for iCount := 0 to iAudio - 1 do
        begin
            sC := sC + ' -add ' + sAudioOuts[iCount];
            if (iaAudio[iCount].lang <> '') then
               sC := sC + ':lang=' + iaAudio[iCount].lang
            else
              case cboALang.ItemIndex of
                1: sC := sC + ':lang=jpn';
                2: sC := sC + ':lang=eng';
                3: sC := sC + ':lang=fre';
                4: sC := sC + ':lang=spa';
              end;
        end;
      end
      else // MKV
      begin
        isMkvResult := True;
      end;
    end;
    1: // vp8 (webm)
    begin
      case cboContainer.ItemIndex of
        0: // MKV
        begin
          isMkvResult := True;
        end;

        1: // WebM
        begin
          sOutput := ChangeFileExt(sOutput, '.webm');
          sC := sPath + 'mkvtoolnix/mkvmerge.exe -w -o "' + sOutput +
            '" ' + sVideoOut;
          for iCount := 0 to iAudio - 1 do
          begin
            if (iaAudio[iCount].lang <> '') then
              sC := sC + ' --language 1:' + iaAudio[iCount].lang
            else
              case cboALang.ItemIndex of
                1: sC := sC + ' --language 1:jpn';
                2: sC := sC + ' --language 1:eng';
                3: sC := sC + ' --language 1:fre';
                4: sC := sC + ' --language 1:spa';
              end;
            sC := sC + ' ' + sAudioOuts[iCount];
          end;
        end;
      end;
    end;
  end;

  if (isMkvResult) then
  begin
	sOutput := ChangeFileExt(sOutput, '.mkv');
	sC := sPath + 'mkvtoolnix/mkvmerge.exe -o "' +
	   sOutput + '" ' + sVideoOut;
	for iCount := 0 to iAudio - 1 do
	begin
	  if (iaAudio[iCount].lang <> '') then
		 sC := sC + ' --language 1:' + iaAudio[iCount].lang
	  else
		case cboALang.ItemIndex of
		  1: sC := sC + ' --language 1:jpn';
		  2: sC := sC + ' --language 1:eng';
		  3: sC := sC + ' --language 1:fre';
		  4: sC := sC + ' --language 1:spa';
		end;
	  sC := sC + ' --no-chapters ' + sAudioOuts[iCount];
	end;
	for iCount := 0 to iSubtitle - 1 do
	  sC := sC + ' ' + sSubtitleOuts[iCount];
	{ // Copy subtitles, chapters and attachment from source (don't need subtitle extract)
	  // Add "--no-chapters" for no chapters copy and -M for no attachment copy.
	if (iSubtitle > 0) then
      sC := sC + ' -A -D "' + sSource + '"';
	}
  end;
end;

{ *** Single Thread *** }
procedure Tfmain.encodeFile_start();
begin
  // While we have something to encode
  while (findSource()) do
  begin
    // Found something, encoding!
    mStart.Enabled := False;
    mPauseResume.Enabled := True;
    mPauseResume.Caption := 'Pause';
    bPause := false;
    mStop.Enabled := True;
    encodeFile();

    // Error?
    if (bStop) then
    begin
      setFileStatus(iFileToEncode+1, 'stopped');
      mStart.Enabled := True;
      break;
    end
    else if (bError) then
    begin
      setFileStatus(iFileToEncode+1, 'error');
      mStart.Enabled := True;
      break;
    end
    else
    begin
      setFileStatus(iFileToEncode+1, 'done');
    end;
  end;

  mStart.Enabled := True;
  mPauseResume.Enabled := False;
  mPauseResume.Caption := 'Pause/Resume';
  mStop.Enabled := False;
end;

procedure Tfmain.encodeFile();
var
  iCount: integer;
begin
  AddLog('Encoding: ' + ExtractFileName(sSource));
  lstFiles.Cells[0, iFileToEncode + 1] := 'encoding';

  // ** Analyse source **
  AddLog('> Running source analysis...');
  makeCmdLineProbe();
  iExitCode := CliRun(sP);
  parseExitCode(iExitCode);
  if (bError) then
    exit;
  parseProbe();
  AddLog('>> ');
  AddLogFin('d: ' + sDuration);
  AddLogFin(', a: ' + IntToStr(iAudio));
  AddLogFin(', s: ' + IntToStr(iSubtitle));

  // Video Bitrate (kbps)
  case (cboVType.ItemIndex) of
    0: // kbps
    begin;
      iVBitrate := StrToInt(txtVBitrate.Text);
    end;

    1: // MB
    begin;
      iVBitrate := calculateVideoBitrate();
    end;
  end;

  makeCmdLine();      // Encoders
  makeCmdLineMerge(); // Merge

  // ** Encode video - Pass 1 **
  AddLog('> Running video analysis...');
  iExitCode := CliRun(sV1);
  parseExitCode(iExitCode);
  if (bError) then
    exit;

  // ** Encode video - Pass 2 **
  AddLog('> Running video encoding...');
  iExitCode := CliRun(sV2);
  parseExitCode(iExitCode);
  if (bError) then
    exit;

  // ** Subs
  for iCount := 0 to iSubtitle - 1 do
  begin
    AddLog('> Running subtitles extraction...');
    iExitCode := CliRun(sExtractSubs[iCount]);
    parseExitCode(iExitCode);
    if (bError) then
      exit;
  end;

  for iCount := 0 to iAudio - 1 do
  begin
    // ** Extracting audio **
    AddLog('> Running audio extraction: track #' + IntToStr(iCount));
    AddLogFin('(' + iaAudio[iCount].lang + ')...');
    iExitCode := CliRun(sExtractAudio[iCount]);
    parseExitCode(iExitCode);
    if (bError) then
      exit;

    // ** Normalize (and downmix if 5.1)
    if (chkFNormAudio.Checked Or iaAudio[iCount].is51) then
    begin
      AddLog('> Running audio filtering...');
      iExitCode := CliRun(sAND[iCount]);
      parseExitCode(iExitCode);
      if (bError) then
        exit;

      // File name fix
      DeleteFile(sTemp + 'audio.wav');
      RenameFile(sTemp + 'audio_sox.wav', sTemp + 'audio.wav');
    end;

    // ** Encode audio **
    AddLog('> Running audio encoding...');
    iExitCode := CliRun(sCod[iCount]);
    parseExitCode(iExitCode);
    if (bError) then
      exit;
  end;

  // ** Merge
  AddLog('> Merging files...');
  iExitCode := CliRun(sC);
  parseExitCode(iExitCode);
  if (bError) then
    exit;

  //  ** Delete temp
  deleteTemp();

  // ** Done!
  AddLog('> Finished.');
  StatusBar1.Panels[1].Text := 'encoding finished.';
end;

procedure Tfmain.parseProbe();
var
  iCpt: integer;
  iPos, iPos2: integer;
  sAux: string;
begin
  sDuration := '';
  // Looking in mencoder's logs for DURATION
  for iCpt := 0 to (oCliLogs.Count -1) do
    if (posStr(oCliLogs.Strings[iCpt], 'Duration:') > 0) then
    begin
      sDuration := MidStr(oCliLogs.Strings[iCpt], 13, 11);
      iDuration := (StrToInt(MidStr(sDuration, 0, 2)) * 3600) +
                (StrToInt(MidStr(sDuration, 4, 2)) * 60) +
                (StrToInt(MidStr(sDuration, 7, 2)));
      break;
    end;

  // Looking for video size
  for iCpt := 0 to (oCliLogs.Count -1) do
  begin
    iPos := posStr(oCliLogs.Strings[iCpt], ': Video: ');
    if (iPos > 0) then
    begin
      sAux := RightStr(oCliLogs.Strings[iCpt], Length(oCliLogs.Strings[iCpt]) - iPos - 9);
      // Codec name
      iPos := posStr(sAux, ', ');
      sAux := RightStr(sAux, Length(sAux) - iPos - 2);
      // Color format?
      iPos := posStr(sAux, ', ');
      sAux := RightStr(sAux, Length(sAux) - iPos - 2);
      // Resolution
      iPos := min(posStr(sAux, ', '), posStr(sAux, ' '));
      sAux := LeftStr(sAux, iPos);
      iPos := posStr(sAux, 'x');
      videoWidth := StrToInt(LeftStr(sAux, iPos));
      videoHeight := StrToInt(RightStr(sAux, Length(sAux) - iPos - 1));
      break;
    end;
  end;

  iAudio := 0;
  // Looking in ffprobe's logs for AUDIO
  for iCpt := 0 to (oCliLogs.Count -1) do
  begin
    iPos := posStr(oCliLogs.Strings[iCpt], ': Audio:');
    if (iPos > 0) then
    begin
      // Position of first point
      iPos2 := posStr(oCliLogs.Strings[iCpt], '.');
      // Track number and / or language
      sAux := MidStr(oCliLogs.Strings[iCpt], iPos2 + 2, iPos - iPos2 - 1);
      iaAudio[iAudio] := parseTrackAudio(sAux, oCliLogs.Strings[iCpt]);
      iAudio := iAudio + 1;
    end;
  end;

  iSubtitle := 0;
  // Looking in ffprobe's logs for SUBS
  for iCpt := 0 to (oCliLogs.Count -1) do
  begin
    iPos := posStr(oCliLogs.Strings[iCpt], ': Subtitle:');
    if (iPos > 0) then
    begin
      // Position of first point
      iPos2 := posStr(oCliLogs.Strings[iCpt], '.');
      // Track number and / or language
      sAux := MidStr(oCliLogs.Strings[iCpt], iPos2 + 2, iPos - iPos2 - 1);
      iaSubtitle[iSubtitle] := parseTrackSubtitle(sAux);
      iSubtitle := iSubtitle + 1;
    end;
  end;
end;

function Tfmain.posStr(val: string; search: string): LongInt;
begin
  Result := sizeint(StrPos(pChar(val), pChar(search))) - sizeint(val)
end;

function Tfmain.parseTrackAudio(val: string; all: string): InfoTypeAudio;
var
  res: InfoTypeAudio;
  iPos: LongInt;
  track, lang: string;
begin
  track := val;
  lang := '';
  iPos := posStr(val, '(');
  if (iPos > 0) then
  begin
    track := MidStr(val, 0, iPos);
    lang := MidStr(val, iPos + 2, 3);
    if (lang = 'und') then
       lang := '';
  end;
  res.track := track;
  res.lang := lang;
  res.is51 := False;

  if (posStr(all, '5.1') > 0) then
     res.is51 := True;

  Result := res;
end;

function Tfmain.parseTrackSubtitle(val: string): InfoTypeSubtitle;
var
  res: InfoTypeSubtitle;
  iPos: LongInt;
  track, lang: string;
begin
  track := val;
  lang := '';
  iPos := posStr(val, '(');
  if (iPos > 0) then
  begin
    track := MidStr(val, 0, iPos);
    lang := MidStr(val, iPos + 2, 3);
    if (lang = 'und') then
       lang := '';
  end;
  res.track := track;
  res.lang := lang;

  Result := res;
end;

function Tfmain.calculateVideoBitrate():integer;
var
  calcul: Double;
  fAudio, fVideo: Double;
begin
  {
   (Size - (Audio x Length )) / Length = Video bitrate
   L = Lenght of the whole movie in seconds
   S = Size you like to use in KB (note 700 MB x 1024 = 716 800 KB)
   A = Audio bitrate in KB/s (note 224 kbit/s = 224 / 8 = 28 KB/s)
   V = Video bitrate in KB/s, to get kbit/s multiply with 8.
  }

  fVideo := strToInt(txtVBitrate.text) * 1024;
  fAudio := (iASumBitrates / 8) * iDuration;
  calcul := ((fVideo - fAudio) / iDuration) * 8;
  Result := round(calcul);
end;

procedure Tfmain.Button1Click(Sender: TObject);
begin
  if (SelectDirectoryDialog1.Execute()) then
    txtOutput.Text := SelectDirectoryDialog1.FileName;
end;

procedure Tfmain.Button2Click(Sender: TObject);
begin
{$IFDEF WIN32}
  ShellExecute(1, 'open', 'http://code.google.com/p/bencos/', nil, nil, 1);
{$ENDIF}
end;

procedure Tfmain.cboACodecChange(Sender: TObject);
begin
  case cboACodec.ItemIndex of
    0: // AAC HE+PS
    begin
      cboAQuality.Clear;
      cboAQuality.Items.Add('16');
      cboAQuality.Items.Add('24');
      cboAQuality.Items.Add('32');
      cboAQuality.Items.Add('48');
      cboAQuality.ItemIndex := 2;
    end;
    1: // AAC HE
    begin
      cboAQuality.Clear;
      cboAQuality.Items.Add('32');
      cboAQuality.Items.Add('48');
      cboAQuality.Items.Add('64');
      cboAQuality.ItemIndex := 2;
    end;
    2: // AAC LC
    begin
      cboAQuality.Clear;
      cboAQuality.Items.Add('64');
      cboAQuality.Items.Add('96');
      cboAQuality.Items.Add('128');
      cboAQuality.Items.Add('192');
      cboAQuality.Items.Add('256');
      cboAQuality.ItemIndex := 2;
    end;
    3: // Vorbis
    begin
      cboAQuality.Clear;
      cboAQuality.Items.Add('48');
      cboAQuality.Items.Add('64');
      cboAQuality.Items.Add('96');
      cboAQuality.Items.Add('128');
      cboAQuality.Items.Add('192');
      cboAQuality.Items.Add('256');
      cboAQuality.ItemIndex := 0;
    end;
  end;
end;

procedure Tfmain.cboVCodec2Change(Sender: TObject);
begin
  cboContainer.Items.Clear;
  chkForceMKV.Enabled := False;

  case cboVCodec2.ItemIndex of
    0: // H264
    begin
      // Preset
      cboVCodecPreset.Items.Clear;
      cboVCodecPreset.Items.Add('Ultra Fast');
      cboVCodecPreset.Items.Add('Super Fast');
      cboVCodecPreset.Items.Add('Very Fast');
      cboVCodecPreset.Items.Add('Faster');
      cboVCodecPreset.Items.Add('Fast');
      cboVCodecPreset.Items.Add('Medium');
      cboVCodecPreset.Items.Add('Slow');
      cboVCodecPreset.Items.Add('Slower');
      cboVCodecPreset.Items.Add('Very Slow');
      cboVCodecPreset.Items.Add('Placebo');
      cboVCodecPreset.ItemIndex := 8;

      // Profile
      cboVCodecProfile.enabled := true;

      // Tune
      cboVCodecTune.enabled := true;

      // Container
      cboContainer.Items.Add('Matroska (MKV)');
      cboContainer.Items.Add('MP4');
      cboContainer.ItemIndex := 0;
      chkForceMKV.Enabled := True;
      chkForceMKV.Checked := True;
      cboACodec.Enabled := True;
      cboACodec.ItemIndex := 0;
      cboACodecChange(Sender);
    end;
    1: // VP8
    begin
      // Preset
      cboVCodecPreset.Items.Clear;
      cboVCodecPreset.Items.Add('Fast');
      cboVCodecPreset.Items.Add('Medium');
      cboVCodecPreset.Items.Add('Slow');
      cboVCodecPreset.ItemIndex := 2;

      // Profile
      cboVCodecProfile.enabled := false;

      // Tune
      cboVCodecTune.enabled := false;

      // Container
      cboContainer.Items.Add('Matroska (MKV)');
      cboContainer.Items.Add('WebM');
      cboContainer.ItemIndex := 0;
      cboACodec.Enabled := False;
      cboACodec.ItemIndex := 3;
      cboACodecChange(Sender);
    end;
  end;
end;

procedure Tfmain.cboVCodecPresetChange(Sender: TObject);
begin

end;

procedure Tfmain.cboVTypeChange(Sender: TObject);
begin
  case cboVType.ItemIndex of
    0: txtVBitrate.Text := '368';
    1: txtVBitrate.Text := '70';
  end;
end;

procedure Tfmain.deleteTemp();
var
  MySearch: TSearchRec;
begin
  FindFirst(sTemp + '*.*', faAnyFile + faReadOnly, MySearch);
  DeleteFile(sTemp + '' + MySearch.Name);
  while FindNext(MySearch) = 0 do
  begin
    DeleteFile(sTemp + '' + MySearch.Name);
  end;
  FindClose(MySearch);
end;

procedure Tfmain.parseExitCode(iExitCode: integer);
var
  iCpt: integer;
begin
  if ((iExitCode <> 0) and (iExitCode <> 1)) then
  begin
    AddLogFin('error #' + IntToStr(iExitCode));
    bError := True;
    if (bStop) then
    begin
      for iCpt := 1 to (lstFiles.RowCount - 1) do
        if (lstFiles.Cells[0, iCpt] = 'encoding') then
          lstFiles.Cells[0, iCpt] := 'ready';
    end
    else
    begin
      for iCpt := 1 to (lstFiles.RowCount - 1) do
        if (lstFiles.Cells[0, iCpt] = 'encoding') then
          lstFiles.Cells[0, iCpt] := 'error';
    end;
  end
  else
  begin
    AddLogFin('done.');
    bError := False;
  end;
end;

procedure Tfmain.AddLog(sMessage: string);
var
  sDate: string;
begin
  sDate := '[' + TimeToStr(time()) + '] ';
  lstLog.Items.Add(sDate + sMessage);
  lstLog.ItemIndex := lstLog.Items.Count - 1;
end;

procedure Tfmain.AddLogFin(sMessage: string);
begin
  lstLog.Items.Strings[lstLog.Items.Count - 1] :=
    lstLog.Items.Strings[lstLog.Items.Count - 1] + ' ' + sMessage;
end;

procedure Tfmain.FormCreate(Sender: TObject);
var
  IsWow64Result: Bool;
begin
  // Class
  aFiles := TStringList.Create();
  oCli := TProcess.Create(nil);
  oCliLogs := TStringList.Create();

  // Defaut
  sPath := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName));
  cboVCodec2Change(Sender);

  // Logs
  AddLog('BENCOS v' + sVersion + ' loaded.');
  AddLog('Compiler: ' + sLazarus);

  // Nero AAC encoder
  bNeroAAC := False;
  if (FileExists(sPath + 'neroAacEnc.exe')) then
  begin
    AddLog('> Addon found: Nero AAC Encoder');
    bNeroAAC := True;
  end;

  // Win64?
  {$IFDEF WIN32}
  if (FileExists('C:\Windows\SysWOW64\calc.exe')) then
  begin
    AddLog('> 64bit system detected');
    sTarget := 'win64';
  end;
  {$ENDIF}

  // Nb core
  {$IFDEF WIN32}
  iNbCore := StrToInt(GetEnvironmentVariable('NUMBER_OF_PROCESSORS'));
  //AddLog('> ' + IntToStr(iNbCore) + ' cores detected');
  {$ENDIF}

  bPause := False;
end;

procedure Tfmain.FormDestroy(Sender: TObject);
begin
  // Class
  aFiles.Free();
  oCli.Free();
  oCliLogs.Free();
end;

procedure Tfmain.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  x: integer;
begin
  for x := 0 to High(FileNames) do
    AddFile(FileNames[x]);
end;

procedure Tfmain.HomeClick(Sender: TObject);
begin
{$IFDEF WIN32}
  ShellExecute(1, 'open', 'http://code.google.com/p/bencos/', nil, nil, 1);
{$ENDIF}
end;

procedure Tfmain.mPauseResumeClick(Sender: TObject);
begin
  if (bPause) then
  begin
    if (oCli.Resume() = 0) then
    begin
      mPauseResume.Caption := 'Pause';
      bPause := False;
    end
    else if (oCli.Resume() = 0) then
    begin
      mPauseResume.Caption := 'Pause';
      bPause := False;
    end;
  end
  else
  begin
    if (oCli.Suspend() = 0) then
    begin
      mPauseResume.Caption := 'Resume';
      bPause := True;
    end;
  end;
end;

procedure Tfmain.MenuItem9Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure Tfmain.mStartClick(Sender: TObject);
begin
  encodeFile_start();
end;

procedure Tfmain.mStopClick(Sender: TObject);
begin
  oCli.Terminate(-1);
  mStart.Enabled := True;
  mPauseResume.Enabled := False;
  mPauseResume.Caption := 'Pause/Resume';
  mStop.Enabled := False;
end;

procedure Tfmain.MenuItem7Click(Sender: TObject);
begin
  {$IFDEF WIN32}
  ShellExecute(1, 'open',
    'https://www.paypal.com/xclick/business=sirber@detritus.qc.ca&no_shipping=1&item_name=Bencos',
    nil, nil, 1);
{$ENDIF}
end;

procedure Tfmain.mnuInfoClick(Sender: TObject);
var
  br: Tfinfo;
  iFile: integer;
begin
  if (aFiles.Count > 0) then
  begin
    iFile := lstFiles.Row - 1;
    if (FileExists(aFiles[iFile]) = False) then
    begin
      ShowMessage('File not found.');
      exit;
    end;
    br := Tfinfo.Create(nil);
    br.sFilename := aFiles[iFile];
    br.ShowModal();
    br.Free;
  end
  else
  begin
    ShowMessage('Queue is Empty');
    exit;
  end;
end;

procedure Tfmain.mnuRemoveClick(Sender: TObject);
var
  X, Y, iCpt, iCount: integer;
begin
  iCount := lstFiles.RowCount - 2; // - Title and Last line
  X := 1; // Files
  for iCpt := iCount downto 1 do
  begin
    Y := iCpt;
    if (X >= lstFiles.Selection.Left) and (X <= lstFiles.Selection.Right) and
      (Y >= lstFiles.Selection.Top) and (Y <= lstFiles.Selection.Bottom) then
    begin
      // Remove
      lstFiles.DeleteColRow(False, iCpt);
      aFiles.Delete(iCpt - 1);
    end;
  end;
end;

procedure Tfmain.mnuAddClick(Sender: TObject);
var
  iCpt: integer;
begin
  if OpenDialog1.Execute then
    for iCpt := 0 to OpenDialog1.Files.Count - 1 do
      AddFile(OpenDialog1.Files[iCpt]);
end;

procedure Tfmain.mnuRemoveAllClick(Sender: TObject);
begin
  // GUI
  lstFiles.RowCount := 2;
  lstFiles.Cells[0, 1] := '';
  lstFiles.Cells[1, 1] := '';

  // Code
  aFiles.Clear;
end;

procedure Tfmain.mnuRemoveFinishedClick(Sender: TObject);
var
  iCpt, iCount: integer;
begin
  iCOunt := lstFiles.RowCount - 2; // - Title and Last line
  for iCpt := iCOunt downto 1 do
  begin
    if (lstFiles.Cells[0, iCpt] = 'done') then
    begin
      // Remove
      lstFiles.DeleteColRow(False, iCpt);
      aFiles.Delete(iCpt - 1);
    end;
  end;
end;

procedure Tfmain.mnuResetStatusClick(Sender: TObject);
var
  X, Y, iCpt, iCount: integer;
begin
  iCount := lstFiles.RowCount - 2; // - Title and Last line
  X := 1; // Files
  for iCpt := iCount downto 1 do
  begin
    Y := iCpt;
    if (X >= lstFiles.Selection.Left) and (X <= lstFiles.Selection.Right) and
      (Y >= lstFiles.Selection.Top) and (Y <= lstFiles.Selection.Bottom) then
    begin
      lstFiles.Cells[0, iCpt] := 'ready';
    end;
  end;
end;

procedure Tfmain.AddFile(sFileName: string);
var
  iNewRow: integer;
  sName: string;
begin
  iNewRow := lstFiles.RowCount;

  if (DirectoryExists(sFileName)) then
    sName := 'DVD on ' + sFileName
  else if (FileExists(sFileName)) then
    sName := ExtractFileName(sFileName)
  else
    exit;

  // Add file (GUI)
  lstFiles.Cells[0, iNewRow - 1] := 'ready';
  lstFiles.Cells[1, iNewRow - 1] := sName;

  // Add file (code)
  aFiles.Add(sFileName);

  // Add new free line
  lstFiles.RowCount := iNewRow + 1;
end;

function Tfmain.CliRun(sCmd: string): integer;
var
  aOutput: TStringList;
  iCpt: integer;
  isFinished: Boolean;
begin
  aOutput := TStringList.Create();
  // http://wiki.lazarus.freepascal.org/Executing_External_Programs
  // http://community.freepascal.org:10000/docs-html/fcl/process/tprocess.execute.html

  oCli.CommandLine := sCmd;
  oCli.Priority := ppIdle;
  oCli.CurrentDirectory := sTemp;
  oCli.Options := [poUsePipes, poStderrToOutPut];
  {$IFDEF WIN32}oCli.Options := oCli.Options + [poNoConsole];{$ENDIF}
  {$IFDEF LINUX}oCli.ShowWindow := swoHide;{$ENDIF}
  oCli.Execute();

  oCliLogs.Clear();
  oCliLogs.Add(sCmd);
  oCliLogs.Add('');
  isFinished := false;

  // One loop after the end of the process to read the final output
  // Issue 17
  while ((oCli.Active = True) or (not isFinished)) do
  begin
    isFinished := (not oCli.Active);
    if (not bPause) then
    begin
      //Look for logs
      aOutput.LoadFromStream(oCli.Output);
      Application.ProcessMessages();
      Sleep(25);
      Application.ProcessMessages();
      if (aOutput.Count > 0) then
      begin
        for iCpt := 0 to aOutput.Count - 1 do
        begin
          oCliLogs.Add(aOutput.Strings[iCpt]);
        end;
        //txtLog.Text := aOutput.Strings[aOutput.Count - 1];
        StatusBar1.Panels[1].Text := aOutput.Strings[aOutput.Count - 1];
      end;
    end
    else
    begin
      Application.ProcessMessages();
      Sleep(25);
    end;
  end;

  aOutput.Free;
  Result := oCli.ExitStatus;
end;

initialization
  {$I umain.lrs}

end.
