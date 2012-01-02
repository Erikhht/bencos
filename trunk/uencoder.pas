{******************************************************
 * uEncoder - Async Process Manager
 * part of BENCOS
 ******************************************************}
unit uencoder;

{$mode objfpc}

interface

uses
  Classes, SysUtils, Process, AsyncProcess, ujob, strutils;

type
  StrArray = Array[0..9] of string;

  encoder = class(TThread)
    private
      iTask: integer; { 0: probe, 1: v/1pass, 2: v/2pass, 3:v/3pass
                        4: a/extract, 5: a/norm, 6: a/enc, 7: merge}
      bIsEncoding: boolean;
      iExitCode: integer;
      oCli: TAsyncProcess;
      oJob: TJob;

      { Logs}
      aOutput: TStringList;
      sStatus: string;

      { Paths }
      oPath: TPath;

      { Command Line}
      sP: string;                           // Probe
      sV, sV1, sV2, SV3: string;            // Video
      sExtractAudio, sAND, sCod: StrArray;  // Audio
      sC: string;                           // Container

      { Command Line }
      procedure makeCmdLine();
      procedure makeCmdLineMerge();
      procedure makeCmdLineProbe();

      { Process }
      procedure execute(sCmd: string);
      procedure ReadData(Sender : TObject);
      procedure Terminate(Sender : TObject);
    public
      constructor Create();
      destructor Destroy();

      { Get / Set}
      function getStatus(): string; // real time status
      procedure setTask(task: integer);
      procedure setJob(job: TJob);

      { Process }
      procedure start();
  end;

implementation

procedure encoder.start();
begin
  bIsEncoding := true;

  if (length(sV) = 0) then
    makeCmdLine();

  if (length(sC) = 0) then
    makeCmdLineMerge();

  if (length(sP) = 0) then
    makeCmdLineProbe();
end;

procedure encoder.ReadData(Sender : TObject);
begin
  aOutput.LoadFromStream(oCli.Output);
  if (aOutput.Count > 0) then
    sStatus := aOutput.Strings[aOutput.Count - 1];
end;

procedure encoder.Terminate(Sender : TObject);
begin
  bIsEncoding := false;
  iExitCode := oCli.ExitStatus;
end;

procedure encoder.execute(sCmd: string);
begin
  // Start
  oCli.CommandLine := sCmd;
  oCli.Execute();
end;

constructor encoder.Create();
begin
  bIsEncoding := false;

  { Process }
  oCli := TAsyncProcess.Create(nil);
  oCli.OnReadData := @ReadData;
  oCli.OnTerminate := @Terminate;
  oCli.Priority := ppIdle;
  oCli.CurrentDirectory := oJob.sTemp;
  oCli.Options := [poUsePipes, poStderrToOutPut];
  {$IFDEF WIN32}oCli.Options := oCli.Options + [poNoConsole];{$ENDIF}
  {$IFDEF LINUX}oCli.ShowWindow := swoHide;{$ENDIF}

  { Logs }
  aOutput := TStringList.Create();
end;

destructor encoder.Destroy();
begin
  oCli.Free();
  aOutput.Free();
end;

procedure encoder.makeCmdLine();
begin

end;

procedure encoder.makeCmdLineMerge();
begin

end;

procedure encoder.makeCmdLineProbe();
begin

end;

function encoder.getStatus(): string;
begin
  Result := sStatus;
end;

procedure encoder.setJob(job: TJob);
begin
  oJob := job;
end;

procedure encoder.setTask(task: integer);
begin
  iTask := task;
end;

end.


