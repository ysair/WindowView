//==============================================================================
// Unit Name: BaseFrm
// Author   : ysai
// Date     : 2003-11-28
// Purpose  :
// History  :
//==============================================================================

//{$DEFINE _XPMENU}

unit BaseFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WindowViewUnit, IniFiles
  {$IFDEF _XPMENU}
  ,XPMenu
  {$ENDIF}
  ;

type
  TFrmBase = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FLanguageFile: string;
    procedure WMSysCommand(var Message:TWMSysCommand);message WM_SYSCOMMAND;

  {$IFDEF _XPMENU}
  protected
    FXPMenu : TXPMenu;
    procedure CreateXPMenu;
  {$ENDIF}

  protected
    FSaveState  : Boolean;
    procedure DoAbout;  virtual;

    procedure CreateParams(var Params:TCreateParams); override;
    procedure SetLanguageFile(const Value: string);
    procedure LoadFormState;virtual;
    procedure SaveFormState;virtual;
    procedure DoCreate; override;
  public
    property SaveState  : Boolean read FSaveState Write FSaveState default True;
    property LanguageFile : string read FLanguageFile Write SetLanguageFile;
    function ShowModal:Integer;reintroduce;override;
    constructor Create(AOwner: TComponent);reintroduce;override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

constructor TFrmBase.Create(AOwner: TComponent);
begin
  FSaveState :=  True;
  with Application do
    SetWindowLong(Handle, GWL_EXSTYLE,
    GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  inherited;
  {$IFDEF _XPMENU}
  CreateXPMenu;
  {$ENDIF}
  if FormStyle <> fsMDIChild then
    AddAboutMenu(Handle);
  Self.LanguageFile :=  GlobalOption.Language;
end;

procedure TFrmBase.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if Owner is TForm then
    Params.WndParent  :=  TForm(Owner).Handle
  else
    Params.ExStyle    :=  Params.ExStyle + WS_EX_APPWINDOW;
end;

procedure TFrmBase.DoAbout;
begin
  ShowAbout;
end;

function TFrmBase.ShowModal: Integer;
begin
  BorderIcons :=  BorderIcons - [biMinimize];
  {if Owner is TForm then
  begin
    TForm(Owner).Enabled  :=  False;
    Show;
    Result  :=  0;
  end
  else//}
    Result  :=  inherited ShowModal;
end;

procedure TFrmBase.WMSysCommand(var Message: TWMSysCommand);
begin
  case Message.CmdType of
    UM_About    :
      DoAbout ;
    SC_MINIMIZE :
      DefWindowProc(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    SC_RESTORE:
      DefWindowProc(Handle, WM_SYSCOMMAND, SC_RESTORE, 0);
  else
    inherited;
  end;
end;

procedure TFrmBase.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Owner is TForm then
    TForm(Owner).Enabled  :=  True;
  Action  :=  caFree;
end;

{$IFDEF _XPMENU}
procedure TFrmBase.CreateXPMenu;
begin
  FXPMenu               :=  TXPMenu.Create(Self);
  FXPMenu.Active        :=  True;
  FXPMenu.AutoDetect    :=  True;
{
  FXPMenu.XPContainers  :=  [];
  FXPMenu.XPControls    :=  [xcMainMenu, xcPopupMenu, xcButton];
//}
  //FXPMenu.FlatMenu      :=  True;
end;
{$ENDIF}

procedure TFrmBase.SetLanguageFile(const Value: string);
begin
  FLanguageFile := Value;
  LoadLanguageFromFile(Self, FLanguageFile);
end;

procedure TFrmBase.LoadFormState;

  function LoadState(
      const AFileName : string;
      var AState    : TFormState
      ):Boolean;
  begin
    Result  :=  False;
    if not FileExists(AFileName) then Exit;
    with TIniFile.Create(AFileName) do
    try
      AState.State  :=  TWindowState(ReadInteger(SIniAppName, SIniState, 0));
      AState.Top    :=  ReadInteger(Self.Name, SIniTop, 0);
      AState.Left   :=  ReadInteger(Self.Name, SIniLeft, 0);
      AState.Width  :=  ReadInteger(Self.Name, SIniWidth, 0);
      AState.Height :=  ReadInteger(Self.Name, SIniHeight, 0);
      Result  :=  True;
    finally
      Free;
    end;
  end;

var
  fs  : TFormState;
begin
  if FSaveState and LoadState(GlobalOption.IniFileName, fs) then
  begin
    if fs.Top     > 0 then Top     :=  fs.Top;
    if fs.Left    > 0 then Left    :=  fs.Left;
    if fs.Width   > 0 then Width   :=  fs.Width;
    if fs.Height  > 0 then Height  :=  fs.Height;
    if fs.State = wsMaximized then
      WindowState :=  wsMaximized;
  end;
end;

procedure TFrmBase.SaveFormState;

  function SaveState(
      const AFileName : string;
      const AState  : TFormState
      ):boolean;
  begin
    try
      with TIniFile.Create(AFileName) do
      try
        WriteInteger(Self.Name, SIniState,  Integer(AState.State));
        if AState.State <> wsMaximized then
        begin
          WriteInteger(Self.Name, SIniTop,    AState.Top);
          WriteInteger(Self.Name, SIniLeft,   AState.Left);
          WriteInteger(Self.Name, SIniWidth,  AState.Width);
          WriteInteger(Self.Name, SIniHeight, AState.Height);
        end;
      finally
        Free;
      end;
      Result  :=  True;
    except
      Result  :=  False;
    end;
  end;

var
  fs  : TFormState;
begin
  if FSaveState then
  begin
    fs.State  :=  WindowState;
    fs.Top    :=  Top   ;
    fs.Left   :=  Left  ;
    fs.Width  :=  Width ;
    fs.Height :=  Height;
    SaveState(GlobalOption.IniFileName, fs);
  end;
end;

destructor TFrmBase.Destroy;
begin
  Self.SaveFormState;
  inherited;
end;

procedure TFrmBase.DoCreate;
begin
  Self.LoadFormState;
  inherited;
end;

end.
