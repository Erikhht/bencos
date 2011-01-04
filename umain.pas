unit umain;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Grids, Process, Buttons, Menus, ExtCtrls, uinfo, AsyncProcess,
  fileutil;

type
  { Tfmain }
  Tfmain = class(TForm)
    btnEncOutput: TButton;
    btnStart: TButton;
    btnStop: TButton;
    btn_donate: TButton;
    Button1: TButton;
    Button2: TButton;
    cboACodec: TComboBox;
    cboALang: TComboBox;
    cboSLang: TComboBox;
    cboAQuality: TComboBox;
    cboContainer: TComboBox;
    cboVCodec: TComboBox;
    chkAForceStereo: TCheckBox;
    chkFResize: TCheckBox;
    chkFRatio: TCheckBox;
    txtFRatio: TEdit;
    txtFResize: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label15: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lstFiles: TStringGrid;
    lstLog: TListBox;
    mmoLogs: TMemo;
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
    txtLog: TEdit;
    txtOutput: TEdit;
    txtVBitrate: TEdit;
    procedure btnEncOutputClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btn_donateClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure cboACodecChange(Sender: TObject);
    procedure cboVCodecChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
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
    sSource, sOutput, sVideoOut, sAudioOut: string;
    sP: string;
    sV, sV1, sV2: string;
    sXA, sA: string;
    sC: string;
    bAudio: boolean;
    iFileToEncode: integer;
    iExitCode: integer;

    procedure AddFile(sFileName: string);
    procedure parseProbe();
    { *** Process *** }
    function findSource(): boolean;
    procedure makeCmdLine;
    { Single Thread (old bencos)}
    procedure encodeFile_start();
    procedure encodeFile();
    function CliRun(sCmd: string): integer;
    { Multi Thread (new bencos)}
    procedure encodeFileMT_start();
    procedure encodeFileMT();
  public
    oCliLogs: TStrings;
    function getFileStatus(iFilePos: integer):string;
    procedure setFileStatus(iFilePos: integer; sStatus: string);
    procedure encodeFileMT_done(Sender: TObject); // so it can be called by the thread
    procedure AddLog(sMessage: string);
    procedure AddLogFin(sMessage: string);
  end;

var
  fmain: Tfmain;

const
  sVersion: string = '2010-01-04 dev';
  sLazarus: string = 'Lazarus-0.9.31-28830-fpc-2.4.3-20101229-win32';
  sTarget: string = 'win32';

implementation

{ Tfmain }
procedure Tfmain.btnStartClick(Sender: TObject);
begin
  //if (chkDMTG.Checked = False) then
    encodeFile_start()
  //else
  //  encodeFileMT_start();
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
begin
  AddLog('Encoding: ' + ExtractFileName(sSource));
  lstFiles.Cells[0, iFileToEncode + 1] := 'encoding';

  // Get temp folder
  sTemp := '/tmp/';
  {$IFDEF WIN32}
  sTemp := GetEnvironmentVariable('TEMP') + '/bencos/';
  {$ENDIF}
  if (DirectoryExists(sTemp) = False) then
    MkDir(sTemp);

  // Probe
  sP := sPath + 'ffmpeg_' + sTarget + '/ffprobe.exe "' + sSource + '"';

  // Video (base)
  sV := sPath + 'ffmpeg_' + sTarget + '/ffmpeg.exe -an -y -threads 8 -i "' + sSource +
    '" -vb ' + txtVBitrate.Text + 'k ';

  // Video (subtitles)
  if (cboContainer.ItemIndex = 1) then // Matroska
  begin
    sV := sV + ' -scodec copy ';
    case cboSLang.ItemIndex of
      1: sV := sV + '-slang jpn ';
      2: sV := sV + '-slang eng ';
      3: sV := sV + '-slang fre ';
    end;
  end;

  // Video (filtering)
  if (chkFResize.Checked = True) then
    sV := sV + ' -s ' + txtFResize.Text + ' ';
  if (chkFRatio.Checked = True) then
    sV := sV + ' -aspect ' + txtFRatio.Text + ' ';

  // Video (codec)
  case cboVCodec.ItemIndex of
    0: // x264 / LQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-slow_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-slow.ffpreset" ';
    end;

    1: // x264 / MQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-slower_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-slower.ffpreset" ';
    end;

    2: // x264 / HQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-veryslow_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-veryslow.ffpreset" ';
    end;

    3: // x264 / anime / LQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-anime_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-anime-lq.ffpreset" ';
    end;

    4: // x264 / anime / MQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-anime_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-anime-mq.ffpreset"';
    end;

    5: // x264 / anime / HQ
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath +
        'presets/libx264-anime_firstpass.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-anime-hq.ffpreset" ';
    end;

    6: // x264 / iPod 320x
    begin
      if (cboContainer.ItemIndex = 1) then // Matroska
        sVideoOut := '"' + sTemp + 'video.mkv"'
      else
        sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath + 'presets/libx264-ipod320.ffpreset" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-ipod320.ffpreset" ';
    end;

    7: // x264 / iPod 640x
    begin
      sVideoOut := '"' + sTemp + 'video.mp4"';
      sV := sV + '-vcodec libx264 -passlogfile ' + sVideoOut;
      sV1 := sV + ' -pass 1 -fpre "' + sPath + 'presets/libx264-ipod640.ffprese" ';
      sV2 := sV + ' -pass 2 -fpre "' + sPath + 'presets/libx264-ipod640.ffpreset" ';
    end;

    8: // vp8 / normal
    begin
      sVideoOut := '"' + sTemp + 'video.webm"';
      sV := sV + '-vcodec libvpx -keyint_min 12 -g 480 -qmax 63 -passlogfile ' +
        sVideoOut;
      sV1 := sV + ' -pass 1 ';
      sV2 := sV + ' -pass 2 -level 300 ';
    end;

    9: // vp8 / slow
    begin
      sVideoOut := '"' + sTemp + 'video.webm"';
      sV := sV + '-vcodec libvpx -keyint_min 12 -g 480 -qmax 63 -passlogfile ' +
        sVideoOut;
      sV1 := sV + ' -pass 1 ';
      sV2 := sV + ' -pass 2 -level 200 ';
    end;

    10: // vp8 / slower
    begin
      sVideoOut := '"' + sTemp + 'video.webm"';
      sV := sV + '-vcodec libvpx -keyint_min 12 -g 480 -qmax 63 -passlogfile ' +
        sVideoOut;
      sV1 := sV + ' -pass 1 ';
      sV2 := sV + ' -pass 2 -level 100 ';
    end;
  end;
  sV1 := sV1 + ' ' + sVideoOut;
  sV2 := sV2 + ' ' + sVideoOut;

  // Audio
  // - extraction
  sXA :=sPath + 'ffmpeg_' + sTarget + '/ffmpeg.exe -vn -y -i "' + sSource + '" -f wav "' +
    sTemp + 'audio.wav" ';
  if (chkAForceStereo.Checked) then
     sXA := sXA + ' -ac 2 ';
  case cboALang.ItemIndex of
    1: sXA := sXA + ' -alang jpn ';
    2: sXA := sXA + ' -alang eng ';
    3: sXA := sXA + ' -alang fre ';
  end;

  // - encoding
  case cboACodec.ItemIndex of
    0: // AAC HE+PS
    begin
      sAudioOut := '"' + sTemp + 'audio.mp4"';
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
      sAudioOut := '"' + sTemp + 'audio.mp4"';
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
      sAudioOut := '"' + sTemp + 'audio.mp4"';
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
        sA := sPath + 'faac.exe -o ' + sAudioOut + '"' + sTemp + 'audio.wav" ';
        case cboAQuality.ItemIndex of
          0: sA := sA + '-b 64';
          1: sA := sA + '-b 96';
          2: sA := sA + '-b 128';
          3: sA := sA + '-b 192';
          4: sA := sA + '-b 256';
        end;
      end;
    end;

    3: // Vorbis
    begin
      sAudioOut := '"' + sTemp + 'audio.ogg"';
      sA := sPath + 'oggenc2.exe ';
      case cboAQuality.ItemIndex of
        0: sA := sA + ' -q -1';
        1: sA := sA + ' -q 0';
        2: sA := sA + ' -q 1';
        3: sA := sA + ' -q 2';
        4: sA := sA + ' -q 3';
      end;
      sA := sA + ' "' + sTemp + 'audio.wav" ';
    end;
  end;

  // Output
  sOutput := IncludeTrailingPathDelimiter(txtOutput.Text) + ExtractFileName(sSource);

  // Merge
  case cboVCodec.ItemIndex of
    0..5: // x264 - PC
    begin
      case cboContainer.ItemIndex of
        0: // MP4
        begin
          sOutput := ChangeFileExt(sOutput, '.mp4');
          sC := sPath + 'MP4Box.exe -new "' + sOutput +
            '" -add "' + sVideoOut + '"';
          if (bAudio) then
            sC := sC + ' -add "' + sAudioOut + '"';
        end;
        1: // MKV
        begin
          sOutput := ChangeFileExt(sOutput, '.mkv');
          sC := sPath + 'mkvtoolnix/mkvmerge.exe -o "' +
            sOutput + '" ' + sVideoOut;
          if (bAudio) then
            sC := sC + ' ' + sAudioOut;
        end;
      end;
    end;
    6..7: // x264 - iPod (m4v)
    begin
      sOutput := ChangeFileExt(sOutput, '.m4v');
      sC := sPath + 'MP4Box.exe -new "' + sOutput +
         '" -add "' + sVideoOut + '"';
      if (bAudio) then
        sC := sC + ' -add "' + sAudioOut + '"';
    end;
    8..10: // vp8 (webm)
    begin
      sOutput := ChangeFileExt(sOutput, '.webm');
      sC := sPath + 'mkvtoolnix/mkvmerge.exe -w -o "' + sOutput +
        '" "' + sVideoOut + '"';
      if (bAudio) then
        sC := sC + ' ' + sAudioOut;
    end;
  end;
end;

{ *** Single Thread *** }
procedure Tfmain.encodeFile_start();
begin
  // While we have something to encode
  while (findSource()) do
  begin
    // Found something, encoding!
    btnStart.Enabled := False;
//    chkDMTG.Enabled := False;
    btnStop.Enabled := True;
    encodeFile();

    // Error?
    if (bStop) then
    begin
      setFileStatus(iFileToEncode+1, 'stopped');
      btnStart.Enabled := True;
      break;
    end
    else if (bError) then
    begin
      setFileStatus(iFileToEncode+1, 'error');
      btnStart.Enabled := True;
      break;
    end
    else
    begin
      setFileStatus(iFileToEncode+1, 'done');
    end;
  end;

  btnStart.Enabled := True;
//  chkDMTG.Enabled := True;
  btnStop.Enabled := False;
end;

procedure Tfmain.encodeFile();
begin
  // ** Create the many commandlines to run **
  makeCmdLine();

  // ** Analyse source **
  AddLog('> Running source analysis...');
  iExitCode := CliRun(sP);
  parseExitCode(iExitCode);
  if (bError) then
    exit;
  parseProbe();
  if (bAudio) then
     AddLogFin(' audio detected.')
  else
     AddLogFin(' no audio detected.');

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

  if (bAudio) then
  begin
    // ** Extracting audio **
    AddLog('> Running audio extraction...');
    iExitCode := CliRun(sXA);
    parseExitCode(iExitCode);
    if (bError) then
      exit;

    // ** Encode audio **
    AddLog('> Running audio encoding...');
    iExitCode := CliRun(sA);
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
  txtLog.Text := 'encoding finished.';
end;

{ *** Multi Thread *** }
procedure Tfmain.encodeFileMT_start();
begin
  if (findSource()) then
  begin
    btnStart.Enabled := False;
//    chkDMTG.Enabled := False;
    btnStop.Enabled := True;
    encodeFileMT();
  end;
end;

procedure Tfmain.parseProbe();
var
  iCpt: integer;
begin
     bAudio := false;
     // Looking in mencoder's logs for AUDIO
     for iCpt := 0 to (oCliLogs.Count -1) do
         if (sizeint(StrPos(pChar(oCliLogs.Strings[iCpt]), 'Audio:')) > 0) then
            bAudio := true;
end;

procedure Tfmain.encodeFileMT();
begin
  makeCmdLine();

  {
  oCliMT := TMyThread.Create(True);
  oCliMT.setTemp(sTemp);
  oCliMT.setCmds(sV1, sV2, sXA, sA, sC);
  oCliMT.OnTerminate := @encodeFileMT_done;
  oCliMT.Resume;
    }
end;

procedure Tfmain.encodeFileMT_done(Sender: TObject);
begin
  {
  if (oCliMT.bError = false) then
    setFileStatus(iFileToEncode+1, 'done')
  else
    setFileStatus(iFileToEncode+1, 'error');

  oCliMT.Free;
  deleteTemp();
  btnStart.Enabled := True;
  chkDMTG.Enabled := True;
  btnStop.Enabled := False;
  encodeFileMT_start(); // when the thread is done, move to the next file
  }
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
      cboAQuality.Items.Add('~32');
      cboAQuality.Items.Add('~48');
      cboAQuality.Items.Add('~64');
      cboAQuality.Items.Add('~96');
      cboAQuality.Items.Add('~128');
      cboAQuality.ItemIndex := 0;
    end;
  end;
end;

procedure Tfmain.cboVCodecChange(Sender: TObject);
begin
  cboContainer.Items.Clear;
  case cboVCodec.ItemIndex of
    0..5: // x264 - PC
    begin
      cboContainer.Enabled := False;
      cboContainer.Items.Add('MP4');
      cboContainer.Items.Add('MKV');
      cboContainer.ItemIndex := 1;
      cboACodec.Enabled := True;
      cboACodec.ItemIndex := 0;
      cboACodecChange(Sender);
    end;
    6..7: // x264 - iPod
    begin
      cboContainer.Enabled := False;
      cboContainer.Items.Add('MP4');
      cboContainer.ItemIndex := 0;
      cboACodec.Enabled := False;
      cboACodec.ItemIndex := 2;
      cboACodecChange(Sender);
    end;
    8..10: // vp8
    begin
      cboContainer.Enabled := False;
      cboContainer.Items.Add('WebM');
      cboContainer.ItemIndex := 0;
      cboACodec.Enabled := False;
      cboACodec.ItemIndex := 3;
      cboACodecChange(Sender);
    end;
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
  if (iExitCode <> 0) then
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

procedure Tfmain.btnEncOutputClick(Sender: TObject);
begin
  if (mmoLogs.Visible) then
  begin
    // Hide
    mmoLogs.Height := 0;
    mmoLogs.Width := 0;
    mmoLogs.Clear;
    mmoLogs.Visible := False;
  end
  else
  begin
    // Logs!
    mmoLogs.Visible := True;
    mmoLogs.Lines := oCliLogs;
    mmoLogs.Height := lstLog.Height;
    mmoLogs.Width := lstLog.Width;
  end;
end;

procedure Tfmain.btnStopClick(Sender: TObject);
begin
  bStop := True;
  btnStop.Enabled := False;
  oCli.Terminate(-1);
end;

procedure Tfmain.btn_donateClick(Sender: TObject);
begin
{$IFDEF WIN32}
  ShellExecute(1, 'open',
    'https://www.paypal.com/xclick/business=sirber@detritus.qc.ca&no_shipping=1&item_name=Bencos',
    nil, nil, 1);
{$ENDIF}
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
begin
  // Class
  aFiles := TStringList.Create();
  oCli := TProcess.Create(nil);
  oCliLogs := TStringList.Create();

  // Defaut
  sPath := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName));
  cboVCodecChange(Sender);

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
begin
  aOutput := TStringList.Create();
  // http://wiki.lazarus.freepascal.org/Executing_External_Programs
  // http://community.freepascal.org:10000/docs-html/fcl/process/tprocess.execute.html

  oCli.CommandLine := sCmd;
  oCli.Priority := ppIdle;
  oCli.CurrentDirectory := sTemp;
  oCli.Options := [poUsePipes, poStderrToOutPut];
  {$IFDEF WIN32}oCli.Options := oCli.Options + [poNoConsole];{$ENDIF}
  //oCli.ShowWindow := swoHide;
  oCli.Execute();

  oCliLogs.Clear();
  oCliLogs.Add(sCmd);
  oCliLogs.Add('');

  while (oCli.Active = True) do
  begin
    //Look for logs
    aOutput.LoadFromStream(oCli.Output);
    Application.ProcessMessages();
    if (aOutput.Count > 0) then
    begin
      for iCpt := 0 to aOutput.Count - 1 do
      begin
        oCliLogs.Add(aOutput.Strings[iCpt]);
      end;
      txtLog.Text := aOutput.Strings[aOutput.Count - 1];
    end;
  end;

  aOutput.Free;
  Result := oCli.ExitStatus;
end;

initialization
  {$I umain.lrs}

end.