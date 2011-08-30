{******************************************************
 * uTools - random set of tools
 * part of BENCOS
 ******************************************************}
unit utools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls;

procedure SaveComponentToFile(Component: TComponent; const FileName: TFileName);
procedure LoadComponentFromFile(Component: TComponent; const FileName: TFileName);

implementation

{
  Save / Load form
  From: http://stackoverflow.com/questions/3163586/delphi-7-best-way-to-save-restore-a-form
}

procedure SaveComponentToFile(Component: TComponent; const FileName: TFileName);
var
  FileStream : TFileStream;
  MemStream : TMemoryStream;
begin
  MemStream := nil;

  if not Assigned(Component) then
    raise Exception.Create('Component is not assigned');

  FileStream := TFileStream.Create(FileName,fmCreate);
  try
    MemStream := TMemoryStream.Create;
    MemStream.WriteComponent(Component);
    MemStream.Position := 0;
    ObjectBinaryToText(MemStream, FileStream);
  finally
    MemStream.Free;
    FileStream.Free;
  end;
end;

procedure LoadComponentFromFile(Component: TComponent; const FileName: TFileName);
var
  FileStream : TFileStream;
  MemStream : TMemoryStream;
  i: Integer;
begin
  MemStream := nil;

  if not Assigned(Component) then
    raise Exception.Create('Component is not assigned');

  if FileExists(FileName) then
  begin
    FileStream := TFileStream.Create(FileName,fmOpenRead);
    try
      for i := Component.ComponentCount - 1 downto 0 do
      begin
        if Component.Components[i] is TControl then
          TControl(Component.Components[i]).Parent := nil;
        Component.Components[i].Free;
      end;

      MemStream := TMemoryStream.Create;
      ObjectTextToBinary(FileStream, MemStream);
      MemStream.Position := 0;
      MemStream.ReadComponent(Component);
      Application.InsertComponent(Component);
    finally
      MemStream.Free;
      FileStream.Free;
    end;
  end;
end;

end.

