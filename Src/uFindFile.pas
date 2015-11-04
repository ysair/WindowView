//==============================================================================
// Unit Name: uFindFile
// Author   : ysai
// Date     : 2003-11-28 
// Purpose  : 
// History  :
//==============================================================================

unit uFindFile;

interface

uses
  SysUtils,Windows,Forms,Classes;

procedure FindFiles(
    const AList       : TStrings;
    const APath       : String;
    const AFileName   : string = '*.*';
    const ASubFolder  : Boolean = False
    );

implementation

procedure FindFiles(
    const AList       : TStrings;
    const APath       : String;
    const AFileName   : string = '*.*';
    const ASubFolder  : Boolean = False
    );
var
  sPath : String;
  info  : TSearchRec;
begin
  if APath[Length(APath)] <> '\' then
    sPath :=  APath + '\'
  else
    sPath :=  APath;

  try
    if 0 = FindFirst(sPath + AFileName, faAnyFile and (not faDirectory),info) then
    begin
      if (info.Name <> '.')
          and (info.Name <> '..')
          and ((info.Attr and faDirectory) <> faDirectory) then
        AList.Add(sPath + info.Name);
      while 0 = FindNext(info) do
        if (info.Name <> '.')
            and (info.Name <> '..')
            and ((info.Attr and faDirectory) <> faDirectory) then
          AList.Add(sPath + info.Name);
    end;
  finally
    FindClose(info.FindHandle);
  end;

  if ASubFolder then
  try
    if 0 = FindFirst(sPath + '*', faAnyFile, info) then
    begin
      if (info.Name <> '.')
          and (info.Name <> '..')
          and ((info.Attr and faDirectory) = faDirectory) then
        FindFiles(AList, sPath + info.Name, AFileName, ASubFolder);
      while 0 = FindNext(info) do
        if (info.Name <> '.')
            and (info.Name <> '..')
            and ((info.Attr and faDirectory) = faDirectory) then
          FindFiles(AList, sPath + info.Name, AFileName, ASubFolder);
    end;
  finally
    FindClose(info.FindHandle);
  end;
end;

end.
