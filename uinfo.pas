unit uinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Process;

type

  { Tfinfo }

  Tfinfo = class(TForm)
    Memo1: TMemo;
    procedure FormActivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    sFilename: string;
  end; 

var
  finfo: Tfinfo;

implementation

{ Tfinfo }

procedure Tfinfo.FormActivate(Sender: TObject);
var
  aOutput: TStringList;
  iCpt: integer;
  oCli: TProcess;
  sPath,
  sCmd: string;
begin
  aOutput := TStringList.Create();
  // http://wiki.lazarus.freepascal.org/Executing_External_Programs
  // http://community.freepascal.org:10000/docs-html/fcl/process/tprocess.execute.html
  
  sPath := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName));
  sCmd := sPath + 'ffmpeg_win32/ffprobe.exe ';
  
  if (FileExists(sCmd) = false) then
  begin
    Memo1.Append('ffprobe.exe not found');
    exit;
  end;
  
  sCmd := sCmd + '"' + sFilename + '"';

  oCli := TProcess.Create(nil);
  oCli.CommandLine := sCmd;
  oCli.Priority := ppIdle;
  oCli.Options := [poUsePipes, poStderrToOutPut];
  {$IFDEF WIN32}
  oCli.Options := oCli.Options + [poNoConsole];
  {$ENDIF}
  oCli.Execute();

  while (oCli.Active = true) do
  begin
    // Do stuff!
    Application.ProcessMessages();
    Sleep(25);
    Application.ProcessMessages();

    //Look for logs
    aOutput.LoadFromStream(oCli.Output);
    if (aOutput.Count > 0) then
    begin
      for iCpt := 0 to aOutput.Count -1 do
      begin
        Application.ProcessMessages();
        if (LeftStr(aOutput.Strings[iCpt], 4) = 'Pos:') then
          continue;
        if (LeftStr(aOutput.Strings[iCpt], 2) = 'A:') then
          continue;
        if (LeftStr(aOutput.Strings[iCpt], 1) = '[') then
          continue;
        if (aOutput.Strings[iCpt] = '') then
          continue;
        Memo1.Append(aOutput.Strings[iCpt]);
      end;
    end;
  end;

  aOutput.Free;
  oCli.Free;
end;

initialization
  {$I uinfo.lrs}

end.

