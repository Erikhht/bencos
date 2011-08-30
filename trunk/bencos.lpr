program bencos;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, umain, uinfo, uencoder, uconfig{, utools};

{$R *.res}

begin
  Application.Title:='Bencos';
  Application.Initialize;
  Application.CreateForm(Tfmain, fmain);
  Application.Run;
end.

