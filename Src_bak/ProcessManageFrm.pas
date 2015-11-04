//==============================================================================
// Unit Name: ProcessManageFrm
// Author   : ysai
// Date     : 2003-11-28
// Purpose  :
// History  :
//==============================================================================

unit ProcessManageFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, BaseFrm,WindowViewUnit, StdCtrls, CheckLst;

type
  TFrmProcessManage = class(TFrmBase)
    lbProcessList: TCheckListBox;
    labProcessList: TLabel;
    btnRefresh: TButton;
    btnEndProcess: TButton;
    btnClose: TButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnEndProcessClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FProcessList      : TList;
    procedure ClearProcessList;
    procedure RefreshProcessList;
    procedure KillSelectProcess(const AutoRefresh : Boolean = True);
  protected
    procedure DoCreate; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

{ TFrmProcessManage }

constructor TFrmProcessManage.Create(AOwner: TComponent);
begin
  inherited;
  FProcessList    :=  TList.Create;
  RefreshProcessList;
end;

destructor TFrmProcessManage.Destroy;
begin
  if Assigned(FProcessList) then
  begin
    ClearProcessList;
    FProcessList.Free;
  end;
  inherited;
end;

procedure TFrmProcessManage.ClearProcessList;
//清除进程列表
var
  i : Integer;
begin
  for i := 0 to FProcessList.Count - 1 do
    Dispose(PProcessInfo(FProcessList.Items[i]));
  FProcessList.Clear;
  lbProcessList.Clear;
end;

procedure TFrmProcessManage.KillSelectProcess(const AutoRefresh: Boolean);
//杀死选择的进程
var
  i : Integer;
begin
  for i := lbProcessList.Count - 1 downto 0 do
    if lbProcessList.Checked[i] then
      KillProcess(PProcessInfo(FProcessList.Items[i]).ProcessID);
  if AutoRefresh then
  begin
    Sleep(200);
    RefreshProcessList;
  end;
end;

procedure TFrmProcessManage.RefreshProcessList;
//刷新进程列表
var
  i : Integer;
begin
  ClearProcessList;
  EnumProcess(FProcessList);
  for i :=  0 to FProcessList.Count - 1 do
    lbProcessList.Items.Add(PProcessInfo(FProcessList.Items[i]).ExeFile);
end;

procedure TFrmProcessManage.btnRefreshClick(Sender: TObject);
begin
  inherited;
  RefreshProcessList;
  lbProcessList.SetFocus;
end;

procedure TFrmProcessManage.btnEndProcessClick(Sender: TObject);
begin
  inherited;
  KillSelectProcess;
  lbProcessList.SetFocus;
end;

procedure TFrmProcessManage.btnCloseClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TFrmProcessManage.FormCreate(Sender: TObject);
begin
  inherited;
  BorderStyle :=  bsSizeable;
  AutoSize    :=  False;
end;

procedure TFrmProcessManage.DoCreate;
begin
  FSaveState      :=  False;
  inherited;
end;

end.
