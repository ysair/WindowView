//==============================================================================
// Unit Name: WindowViewFrm
// Author   : ysai
// Date     : 2003-11-28 
// Purpose  : 
// History  :
//==============================================================================

unit WindowViewFrm;

interface

uses
  Windows, SysUtils, Classes, Forms, ExtCtrls, StdCtrls, Controls, Buttons,
  Graphics, ComCtrls,Messages, Menus, ActnList,shellapi,Registry,Clipbrd,
  StrUtils,WindowViewUnit, ToolWin, ImgList, ActnMan, ActnCtrls, CommCtrl,
  BaseFrm, Dialogs,uFindFile, CheckLst,ProcessManageFrm,IniFiles,
  CoolTrayIcon, PSAPI;

Type
  TFrmWindowView = class(TFrmBase)
    spl: TSplitter;
    tv: TTreeView;
    lw: TListBox;
    staBar: TStatusBar;
    ColBar: TCoolBar;
    TolBarMenu: TToolBar;
    tbFile: TToolButton;
    tbOption: TToolButton;
    tbHelp: TToolButton;
    ActList: TActionList;
    acExit: TAction;
    acAutoHide: TAction;
    acStayOnTop: TAction;
    acLanguage: TAction;
    acAbout: TAction;
    acLockCapture: TAction;
    pmFile: TPopupMenu;
    pmfExit: TMenuItem;
    pmOption: TPopupMenu;
    pmoAutoHide: TMenuItem;
    pmoStayOnTop: TMenuItem;
    pmoLanguage: TMenuItem;
    pmHelp: TPopupMenu;
    pmhAbout: TMenuItem;
    imgListSmall: TImageList;
    ImgListLarge: TImageList;
    acEnable: TAction;
    acDisable: TAction;
    pmActions: TPopupMenu;
    pmaEnable: TMenuItem;
    pmaDisable: TMenuItem;
    acCopy: TAction;
    acCopy1: TMenuItem;
    acShow: TAction;
    acHide: TAction;
    pmaShow: TMenuItem;
    pmaHide: TMenuItem;
    acExport: TAction;
    pmaExport: TMenuItem;
    dlgSave: TSaveDialog;
    tbAction: TToolButton;
    acProcessManage: TAction;
    pmTools: TPopupMenu;
    acCaptureAll: TAction;
    acDelete: TAction;
    pmaClose: TMenuItem;
    acCapture: TAction;
    TolBarButton: TToolBar;
    panCapture: TPanel;
    tbLockCapture: TToolButton;
    tbCaptureAll: TToolButton;
    tbSeparator1: TToolButton;
    tbAutoHide: TToolButton;
    tbStayOnTop: TToolButton;
    tbSeparator2: TToolButton;
    tbAbout: TToolButton;
    TolBarSearch: TToolBar;
    panSearch: TPanel;
    panSearchCommand: TPanel;
    edtSearch: TEdit;
    btnSearch: TButton;
    imgListTree: TImageList;
    pmaExpandMenu: TMenuItem;
    acExpandMenu: TAction;
    pmTrayIcon: TPopupMenu;
    acShowWindow: TAction;
    pmtShowWindow: TMenuItem;
    pmtN1: TMenuItem;
    pmtExit: TMenuItem;
    tmeMemory: TTimer;
    tmeInvertTracker: TTimer;
    pmtProcessManage: TMenuItem;
    pmfN1: TMenuItem;
    procedure acAboutExecute(Sender: TObject);
    procedure acCaptureAllExecute(Sender: TObject);
    procedure acExitExecute(Sender: TObject);
    procedure acLockCaptureExecute(Sender: TObject);
    procedure acStayOnTopExecute(Sender: TObject);
    procedure ActionsExecute(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure CaptureMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
    procedure CaptureMouseMove(Sender: TObject; Shift: TShiftState; X,
          Y: Integer);
    procedure CaptureMouseUp(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
    procedure DisplayNode;
    procedure edtSearchKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure NullAction(Sender: TObject);
    procedure pmActionsPopup(Sender: TObject);
    procedure SetInterfaceLanguage(ALanguage:string='');
    procedure TolBarSearchResize(Sender: TObject);
    procedure ToolsExecute(Sender: TObject);
    procedure tvChange(Sender: TObject; Node: TTreeNode);
    procedure tvMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
    procedure acAboutUpdate(Sender: TObject);
    procedure acShowWindowExecute(Sender: TObject);
    procedure tmeMemoryTimer(Sender: TObject);
    procedure staBarResize(Sender: TObject);
    procedure tmeInvertTrackerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FIsCapture        : Boolean;  //是否在捕获状态
    FIsLockCapture    : Boolean;  //是否在锁定捕获状态
    FAtom_LockCapture : HWND;
    FLastHandle       : HWND;
    FHotKey_LockCapture : array[0..1] of Integer;
    TrayIcon: TCoolTrayIcon;
    FInvertTrackerHandle  : HWND;
    FInvertTrackerStatus  : Boolean;
    FInvertTrackerCount   : Integer;

    procedure WMTimer (var Message: TMessage); message WM_TIMER;
    procedure WMHotKey(var Message: TMessage); message WM_HOTKEY;
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;

    procedure FreeNode(const ANode : TTreeNode);

    procedure StartCapture;
    procedure EndCapture;
    procedure SetIsCapture(const Value: Boolean);

    procedure SelectLanguage(Sender: TObject);

    function  GetWindowMenu(const AHwnd  : HWnd):Boolean;
    function  GetSubMenuItems(const AHWnd  : HWnd):Boolean;

    //procedure EnumToolBarButtons(const AHwnd:HWnd);

    procedure GetData(const AInvertTracker  : Boolean = True);
    procedure GetDetailData(const AHandle : HWND);
    procedure RefreshTree;
    procedure ResetLastInvertTrackerHandle;
    procedure InvertTrackerNode(const ANode  : TTreeNode);
    function  CheckNodeData : Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property  IsCapture  : Boolean read FIsCapture write SetIsCapture;
    property  IsLockCapture : Boolean read FIsLockCapture Write FIsLockCapture;
  published
  end;

var
  FrmWindowView  : TFrmWindowView;

implementation

{$R *.dfm}

var
  hMainForm     : HWND;
  ndParent      : TTreeNode;
  hParent       : HWnd;
  hWndLast      : HWnd;
  hWindow       : HWnd;
  hClientWindow : HWnd;
  pMouse        : TPoint;

const
  UM_TIMER_CAPTURE        = WM_USER + $001; //定时捕获消息
  UM_TIMER_ENDCAPTURE     = WM_USER + $002; //结束捕获的定时器消息
  UM_TIMER_HOOKWINDOW     = WM_USER + $003; //定时挂钩
  TIMER_ELAPSE_CAPTURE    = 10;             //定时捕获的时间间隔
  TIMER_ELAPSE_ENDCAPTURE = 100;            //定时检查是否结束捕获的时间间隔
  TIMER_ELAPSE_HOOKWINDOW = 1000;           //定时挂钩间隔

function EnumChildProc(AHWnd: HWnd; lp:lParam):boolean; stdcall;
//回调过程,枚举子窗口

  procedure EnumToolButtons(AHwnd : HWND);
  begin
    beep;
  end;

var
  tn          : TTreeNode;
  ctn         : TTreeNode;
  hi          : PHandleInfo;
  h           : HWnd;
begin
  case lp of
    3 :
      begin
        if IsWindowVisible(AHWnd) then
          HookWindow(hMainForm, AHWnd);
      end;
    else begin
      if GetParent(AHWnd)=hParent then
      begin
        //如果父是调用窗口则
        with FrmWindowView do
        begin
          New(hi);
          hi.HandleType :=  Window;
          hi.Hwnd       :=  AHwnd;
          hi.HandleInfo :=  GetWindowInfo(AHwnd);
          tn  :=  tv.Items.AddChildObject(ndParent,
              PWindowInfo(hi.HandleInfo).Text + ' - '+
              PWindowInfo(hi.HandleInfo).ClassName + '(' +
              IntToStr(PWindowInfo(hi.HandleInfo).Left) + ',' +
              IntToStr(PWindowInfo(hi.HandleInfo).Top) + ',' +
              IntToStr(PWindowInfo(hi.HandleInfo).Width) + ',' +
              IntToStr(PWindowInfo(hi.HandleInfo).Height) + ')'
              , hi);
        end;

        ctn       :=  ndParent;
        ndParent  :=  tn;
        h         :=  hParent;
        hParent   :=  AHwnd;
        //枚举子窗口
        //if SendMessage(AHwnd, TB_BUTTONCOUNT, 0, 0) > 0 then
        //  EnumToolButtons(AHwnd)
        //else
          EnumChildWindows(AHWnd, @EnumChildProc, 1);
        hParent   :=  h;
        ndParent  :=  ctn;
      end;
    end;  //case else
  end;
  Result := True;
end;

constructor TFrmWindowView.Create(AOwner: TComponent);
//初始化
begin
  inherited;
  hMainForm :=  Self.Handle;
  FAtom_LockCapture :=  GlobalAddAtom('MyHotKey') - $C000;
  FHotKey_LockCapture[0]  :=  MOD_CONTROL;
  FHotKey_LockCapture[1]  :=  VkKeyScan('`');
  //注册热键
  RegisterHotKey(
      Handle,
      FAtom_LockCapture,
      FHotKey_LockCapture[0],
      FHotKey_LockCapture[1]);
  SetTimer(Handle, UM_TIMER_HOOKWINDOW, TIMER_ELAPSE_HOOKWINDOW, nil);

  //初始化任务栏图标
  TrayIcon  := TCoolTrayIcon.Create(Self);
  TrayIcon.PopupMenu  :=  pmTrayIcon;
  TrayIcon.MinimizeToTray :=  True;
  TrayIcon.OnDblClick :=  acShowWindowExecute;
  TrayIcon.Icon   :=  Icon;
  TrayIcon.Hint   :=  SAppName;
  TrayIcon.IconVisible := True;
end;

destructor TFrmWindowView.Destroy;
//注销热键
begin
  KillTimer(Handle, UM_TIMER_HOOKWINDOW);
  UnregisterHotKey(Handle, FAtom_LockCapture);
  GlobalDeleteAtom(FAtom_LockCapture);
  TrayIcon.Free;
  inherited;
end;

function TFrmWindowView.GetWindowMenu(const AHwnd : HWnd):Boolean;
//取得菜单
var
  hMainMenu : HWND;
  tn        : TTreeNode;
  ctn       : TTreeNode;
  hi        : PHandleInfo;
begin
  hMainMenu :=  GetMenu(AHwnd);
  if (hMainMenu>0) and (GetMenuItemCount(hMainMenu)>0) then
  begin
    New(hi);
    hi.HandleType  :=  MainMenu;
    hi.Hwnd        :=  hMainMenu;
    hi.HandleInfo  :=  nil;
    tn        :=  tv.Items.AddChildObject(ndParent, SMenu, hi);
    ctn       :=  ndParent;
    ndParent  :=  tn;
    GetSubMenuItems(hMainMenu);
    ndParent  :=  ctn;
    Result    :=  True;
  end
  else
    Result    :=  False;
end;

function TFrmWindowView.GetSubMenuItems(const AHWnd : HWnd):Boolean;
//取得子菜单
var
  i         : Integer;
  hMenu     : HWND;
  tn        : TTreeNode;
  ctn       : TTreeNode;
  hi        : PHandleInfo;
begin
  if GetMenuItemCount(AHwnd)>0 then
  begin
    ctn       :=  ndParent;
    for i:=0 to GetMenuItemCount(AHwnd)-1 do
    begin
      hMenu   := GetSubMenu(AHWnd, i);
      New(hi);
      hi.HandleType  :=  MenuItem;
      hi.Hwnd        :=  AHWnd;//hMenu;
      hi.HandleInfo  :=  GetSubMenuItemInfo(AHWnd, i);
      tn:=tv.Items.AddChildObject(ndParent,
          PMenuItemInfo(hi.HandleInfo).Caption, hi);
      ndParent  :=  tn;
      GetSubMenuItems(hMenu);
      ndParent  :=  ctn;
    end;
    ndParent  :=  ctn;
    Result:=True;
  end
  else
    Result:=False;
end;

{procedure TFrmWindowView.EnumToolBarButtons(const AHwnd:HWnd);
//枚举工具栏按钮
var
  tn  : TTreeNode;
  ctn : TTreeNode;
  hi  : PHandleInfo;
  h   : HWnd;
  i   : Integer;
begin
  ctn       :=  ndParent;
  ndParent  :=  tn;
  h         :=  hParent;


  hParent   :=  h;
  ndParent  :=  ctn;
end;}


procedure TFrmWindowView.GetData(const AInvertTracker  : Boolean = True);
//取得父窗口列表
var
  hChild  : HWND;
  i : Integer;
begin
  GetCursorPos(pMouse);
  hWindow       :=  WindowFromPoint(pMouse);
  Windows.ScreenToClient(hWindow, pMouse);
  hClientWindow :=  ChildWindowFromPoint(hWindow, pMouse);
  if hClientWindow  <> 0 then hWindow :=  hClientWindow;

  if hWndLast = hWindow then Exit;

  LockWindowUpdate(tv.Handle);
  try
    tv.Items.Clear;
    hChild    :=  hWindow;
    hParent   :=  hWindow;

    //循环取出所有
    while hWindow <>  0 do
    begin
      tv.Items.Insert(tv.TopItem, GetWindowText(hWindow)+' - '+GetClassName(hWindow));
      hParent :=  hWindow;
      hWindow :=  GetParent(hWindow);
    end;
    for i := 1 to tv.Items.Count - 1 do
      tv.Items[i].MoveTo(tv.Items[i-1], naAddChild);
    tv.Items[tv.Items.Count - 1].Selected :=  True;
    {if Assigned(tv.TopItem) then
      tv.TopItem.Expand(true);//}
  finally
    LockWindowUpdate(0);
  end;

  //if hParent<>Handle then
  //begin
    if hWndLast <> 0 then
      if AInvertTracker and (hWndLast <>  panCapture.Handle) then
        InvertTracker(hWndLast);
    if AInvertTracker and (hChild <>  panCapture.Handle) then
      InvertTracker(hChild);
    hWndLast := hChild;
  //end;
end;

procedure TFrmWindowView.FreeNode(const ANode: TTreeNode);
//释放节点数据
var
  i : Integer;
begin
  if Assigned(ANode) then
  begin
    for i := ANode.Count - 1 downto 0 do
      FreeNode(ANode.Item[i]);
    if Assigned(ANode.Data) then
    begin
      Dispose(PHandleInfo(ANode.Data).HandleInfo);
      Dispose(ANode.Data);
    end;
    ANode.Free;
  end;
end;

procedure TFrmWindowView.GetDetailData(const AHandle : HWND);
//取得详细的信息
begin
  FLastHandle :=  AHandle;
  RefreshTree;
end;

procedure TFrmWindowView.RefreshTree;
//刷新树
var
  i   : Integer;
  tn  : TTreeNode;
  hi  : PHandleInfo;
begin
  Screen.Cursor :=  crHourGlass;
  LockWindowUpdate(tv.Handle);
  try
    for i :=  0 to tv.Items.Count - 1 do
      if Assigned(tv.Items[i].Data) then
      begin
        Dispose(PHandleInfo(tv.Items[i].Data).HandleInfo);
        Dispose(tv.Items[i].Data);
      end;
    tv.Items.Clear;
    ndParent  :=  nil;
    New(hi);
    hi.Hwnd       :=  FLastHandle;
    hi.HandleType :=  Window;
    hi.HandleInfo :=  GetWindowInfo(FLastHandle);
    //增加根结点
    tn  :=  tv.Items.AddChildObjectFirst(ndParent,
        PWindowInfo(hi.HandleInfo).Text+' - '+
        PWindowInfo(hi.HandleInfo).ClassName + '(' +
        IntToStr(PWindowInfo(hi.HandleInfo).Left) + ',' +
        IntToStr(PWindowInfo(hi.HandleInfo).Top) + ',' +
        IntToStr(PWindowInfo(hi.HandleInfo).Width) + ',' +
        IntToStr(PWindowInfo(hi.HandleInfo).Height) + ')'
        , hi);

    ndParent  :=  tn;
    hParent   :=  FLastHandle;
    //开始枚举
    GetWindowMenu(FLastHandle);
    EnumChildWindows(FLastHandle, @EnumChildProc, 0);
    ndParent.Expand(False);
    ndParent.Selected :=  True;
  finally
    LockWindowUpdate(0); 
    Screen.Cursor :=  crDefault;
  end;
end;

procedure TFrmWindowView.CaptureMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//开始捕获
begin
  StartCapture;
end;

procedure TFrmWindowView.CaptureMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
//跟踪显示内容
begin
  if GetCapture<>0 then GetData;
end;

procedure TFrmWindowView.CaptureMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//取得详细信息,结束捕获
begin
  //if Button <>  mbLeft  then Exit;
  EndCapture;
end;

procedure TFrmWindowView.DisplayNode;
//显示结点资料
begin
  if not lw.Visible then Exit;
  if Assigned(tv.Selected) and Assigned(tv.Selected.Data) then
    with PHandleInfo(tv.Selected.Data)^, lw.Items do
    begin
      Clear;
      Add(Format('0x%.8x', [HWnd]));
      if Assigned(HandleInfo) then
        case HandleType of
          Window:
            with PWindowInfo(HandleInfo)^ do
            begin
              Add(ClassName);
              Add(Text);
              Add(BoolToStr(Enabled, True));
              //EnableWindow(Hwnd, True);
            end;
          MenuItem:
            with PMenuItemInfo(HandleInfo)^ do
            begin
              Add(sCaption);
              //Add(BoolToStr(bEnabled, True));
            end;
        end;  //case
    end;  //with
end;

procedure TFrmWindowView.FormCreate(Sender: TObject);
//初始化

  procedure CreateLanguageMenu;
  var
    i   : Integer;
    ls  : TStrings;
    mi  : TMenuItem;
    s   : string;
  begin
    ls  :=  TStringList.Create;
    try
      FindFiles(ls, ExtractFilePath(Application.ExeName), '*.ini');
      for i := 0 to ls.Count -1 do
      begin
        with TIniFile.Create(ls[i]) do
        try
          s :=  ReadString(SIniLanguage, SLanguageName, '');
        finally
          Free;
        end;
        if s <> '' then
        begin
          mi          :=  TMenuItem.Create(pmoLanguage);
          mi.Hint     :=  ls[i];
          mi.Caption  :=  s;
          mi.OnClick  :=  SelectLanguage;
          pmoLanguage.Add(mi);
        end; 
      end;
      acLanguage.Visible := pmoLanguage.Count > 0; 
    finally
      ls.Free;
    end;
  end;

var
  panTemp : TPanelEx;
begin
  SetWindowLong(Application.Handle, GWL_EXSTYLE,
      GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);

  acAutoHide.Checked  :=  GlobalOption.bAutoHide;
  acStayOnTop.Checked :=  GlobalOption.bStayOnTop;

  panTemp             :=  TPanelEx.Create(Self);
  panTemp.Parent      :=  panCapture.Parent;
  panTemp.Left        :=  panCapture.Left;
  panTemp.Width       :=  panCapture.Width;
  panTemp.Caption     :=  panCapture.Caption;
  panTemp.BevelOuter  :=  bvNone;
  panTemp.Font.Size   :=  12;
  panTemp.Font.Style  :=  [fsBold];
  panTemp.OnMouseDown :=  panCapture.OnMouseDown;
  panCapture.Free;
  panCapture          :=  panTemp;

  //Assert(False,'这是一个测试程序' + IntToStr(1));
  CreateLanguageMenu;
  //SetInterfaceLanguage(GlobalOption.Language);

  btnSearch.Align :=  alRight;
  edtSearch.Align :=  alClient;

  Caption := '0';
end;

procedure TFrmWindowView.SetInterfaceLanguage(ALanguage:string='');
//设置语言
begin
  GlobalOption.Language   :=  ALanguage;
  Self.LanguageFile :=  GlobalOption.Language;
end;

procedure TFrmWindowView.acExitExecute(Sender: TObject);
//关闭
begin
  Close;
end;

procedure TFrmWindowView.acStayOnTopExecute(Sender: TObject);
//是否总在最前
begin
  if acStayOnTop.Checked then
    SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE+SWP_NOSIZE)
  else
    SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE+SWP_NOSIZE);
end;

procedure TFrmWindowView.acAboutExecute(Sender: TObject);
//关于
begin
  ShowAbout;
end;

procedure TFrmWindowView.tvChange(Sender: TObject; Node: TTreeNode);
//显示节点资料
begin
  if not IsCapture then
  begin
    if CheckNodeData then
    begin
      InvertTrackerNode(tv.Selected);
      DisplayNode;
    end;
  end;
end;

procedure TFrmWindowView.FormDestroy(Sender: TObject);
//保存设置
begin
  GlobalOption.bAutoHide   :=  acAutoHide.Checked;
  GlobalOption.bStayOnTop  :=  acStayOnTop.Checked;
end;

procedure TFrmWindowView.FormShow(Sender: TObject);
//是否在最上
begin
  acStayOnTopExecute(acStayOnTop);
  edtSearch.SetFocus;
end;

procedure TFrmWindowView.NullAction(Sender: TObject);
begin
//空动作,不要删除
end;

procedure TFrmWindowView.StartCapture;
//开始捕获
begin
  if IsLockCapture then Exit;
  if acAutoHide.Checked then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW+SWP_NOSIZE+SWP_NOMOVE);
  if SetCapture(handle) <> 0 then
  begin
    Screen.Cursor :=  crHandPoint;
    IsCapture     :=  True;
    GetData;
    TolBarButton.Refresh;
  end;
end;

procedure TFrmWindowView.EndCapture;
//结束捕获
begin
  if IsLockCapture then Exit;
  If hWindow <> 0 Then
  begin //获得窗口标题
    Windows.ScreenToClient(hWindow, pMouse);
    hClientWindow :=  ChildWindowFromPoint(hWindow, pMouse);
    if hClientWindow  <> 0 then hWindow :=  hClientWindow;
    //while not IsChild(hWindow,hClientWindow) do
    //begin
    //  hWindow:=GetParent(hWindow);
    //end;
    InvertTracker(hWndLast);
    Screen.Cursor := crDefault;
    ReleaseCapture;

    GetDetailData(hWindow);
    ndParent.Selected:=True;

    hWndLast    := 0;
    hWindow     := 0;
    IsCapture   :=  False;
  end;
  panCapture.BevelOuter  :=  bvNone;
  if acAutoHide.Checked then
  begin
    ShowWindow(Handle, SW_SHOW);
    SetForegroundWindow(Handle);
  end;
  //TolBarButton.Refresh;
end;

procedure TFrmWindowView.acLockCaptureExecute(Sender: TObject);
//锁定捕获
begin
  if IsCapture then Exit;
  FIsLockCapture  :=  acLockCapture.Checked;
  if acLockCapture.Checked then
  begin
    SetTimer(Handle, UM_TIMER_CAPTURE, TIMER_ELAPSE_CAPTURE, nil);
  end
  else begin
    KillTimer(Handle, UM_TIMER_CAPTURE);
    GetDetailData(hWindow);
  end;
end;

procedure TFrmWindowView.acCaptureAllExecute(Sender: TObject);
//抓取所有句柄
begin
  inherited;
  Screen.Cursor :=  crHourGlass;
  try
    GetDetailData(0);
  finally
    Screen.Cursor :=  crDefault;
  end;
end;

procedure TFrmWindowView.SetIsCapture(const Value: Boolean);
//设置是否捕获
begin
  FIsCapture := Value;
  if Value then
    SetTimer(Handle, UM_TIMER_ENDCAPTURE, TIMER_ELAPSE_ENDCAPTURE, nil)
  else
    KillTimer(Handle, UM_TIMER_ENDCAPTURE);
end;

procedure TFrmWindowView.WMTimer(var Message: TMessage);
//定时消息
begin
  case Message.wParam of
    UM_TIMER_CAPTURE    : //定时捕获
      if IsLockCapture then GetData(False);
    UM_TIMER_ENDCAPTURE : //按系统键后会丢失鼠标捕获,这时结束捕获
      if (GetCapture =  0) and IsCapture then EndCapture;
    UM_TIMER_HOOKWINDOW : //挂钩窗口
    begin
      //EnumChildWindows(0, @EnumChildProc, 3);
      //Caption :=  IntToStr(FCount);
    end;
  end;
end;

procedure TFrmWindowView.WMHotKey(var Message: TMessage);
//热键消息
begin
  if (Message.LparamLo = FHotKey_LockCapture[0])
      and (Message.LParamHi = FHotKey_LockCapture[1]) then
    tbLockCapture.Click;
end;

procedure TFrmWindowView.ActionsExecute(Sender: TObject);
//节点动作

  procedure ExpandChild(
      const ANode   : TTreeNode;
      const AList   : TStrings;
      const ALevel  : string = ''
      );
  //展开子节点
  var
    i       : Integer;
  begin
    if ANode.Count = 0 then Exit;
    for i := 0 to ANode.Count - 2 do
    begin
      AList.Add(ALevel + '├' +ANode.Item[i].Text);
      ExpandChild(ANode.Item[i], AList, ALevel + '│');
    end;
    AList.Add(ALevel + '└' +ANode.Item[ANode.Count-1].Text);
    ExpandChild(ANode.Item[ANode.Count-1], AList, ALevel + ' ');
  end;

  procedure ExportNode(
      const ANode     : TTreeNode;
      const AFileName : string
      );
  //导出节点
  var
    aList : TStrings;
  begin
    aList :=  TStringList.Create;
    try
      aList.Add(ANode.Text);
      ExpandChild(ANode, aList);
      aList.SaveToFile(AFileName);
    finally
      aList.Free;
    end;
  end;

var
  iHandle : HWND;
begin
  if not Assigned(tv.Selected) or not Assigned(tv.Selected.Data) then Exit;
  iHandle :=  PHandleInfo(tv.Selected.Data).Hwnd;
  case TComponent(Sender).Tag of
    0 :   //复制
      Clipboard.SetTextBuf(PChar(tv.Selected.Text));
    1 :   //Enagled
      case PHandleInfo(tv.Selected.Data).HandleType of
        Window    : EnableWindow(iHandle, True);
        MenuItem  : EnableMenuItem(iHandle,
            PMenuItemInfo(PHandleInfo(tv.Selected.Data).HandleInfo).Command,
            MF_BYCOMMAND or MF_ENABLED);
      end;
    2 :   //disabled
      case PHandleInfo(tv.Selected.Data).HandleType of
        Window    : EnableWindow(iHandle, False);
            //SetWindowLong(iHandle, GWL_STYLE, 
        MenuItem  : EnableMenuItem(iHandle, 
            PMenuItemInfo(PHandleInfo(tv.Selected.Data).HandleInfo).Command, 
            MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
      end;
    3 :   //显示
      ShowWindow(iHandle, SW_SHOW);
    4 :   //隐藏
      ShowWindow(iHandle, SW_HIDE);
    5 :   //删除
      begin
        case PHandleInfo(tv.Selected.Data).HandleType of
          Window    : PostMessage(iHandle, WM_SYSCOMMAND, SC_CLOSE, 0);
          MenuItem  :
            with PHandleInfo(tv.Selected.Data)^ do
              DeleteMenu(HWnd, PMenuItemInfo(HandleInfo).Command, MF_BYCOMMAND);
        end;
        FreeNode(tv.Selected);
      end;
    6 : //扩展菜单
      begin
        case PHandleInfo(tv.Selected.Data).HandleType of
          Window    : HookWindow(hMainForm, iHandle);
          MenuItem  : ;
        end;
      end;
    9:if dlgSave.Execute then
        ExportNode(tv.Selected, dlgSave.FileName);
  end;  //case
end;

procedure TFrmWindowView.tvMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//鼠标事件
var
  ndTemp  : TTreeNode;
begin
  ndTemp  :=  tv.GetNodeAt(X, Y);
  if Assigned(ndTemp) then
  begin
    tv.OnChange :=  nil;
    ndTemp.Selected  :=  True;
    tv.OnChange :=  tvChange;
    case button of
      mbLeft  : //左键,闪烁窗口
        begin
          if not IsCapture then
          InvertTrackerNode(tv.Selected);
        end;
      mbRight : //右键选择,弹出菜单
        begin
          pmActions.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
        end;
    end;
  end;
end;

procedure TFrmWindowView.TolBarSearchResize(Sender: TObject);
//调整位置
begin
  panSearchCommand.Width  :=  TolBarSearch.Width  - panSearchCommand.Left;
end;

procedure TFrmWindowView.btnSearchClick(Sender: TObject);
//查找节点内容

  function FindChild(
      const ANode   : TTreeNode;
      const AText   : string;
      const AStart  : Integer = 0
      ):Boolean;
  //遍历子节点
  var
    i : Integer;
  begin
    Result  :=  False;
    for i := AStart to ANode.Count - 1 do
    begin
      if Pos(AText, UpperCase(ANode.Item[i].Text)) > 0 then
      begin
        ANode.Item[i].Selected  :=  True;
        Result  :=  True;
        Exit;
      end;
      Result  :=  FindChild(ANode.Item[i], AText);
      if Result then Exit;
    end;
  end;

  function FindParent(
      const ANode   : TTreeNode;
      const AText   : string
      ):Boolean;
  //遍历父节点
  begin
    Result  :=  False;
    if not Assigned(ANode.Parent) then Exit;
    Result  :=  FindChild(ANode.Parent, AText, ANode.Index + 1);
    if not Result then
      Result  :=  FindParent(ANode.Parent, AText);
  end;

var
  sSearchText : string;
begin
  if not Assigned(tv.Selected) or (edtSearch.Text = '') then Exit;
  sSearchText :=  UpperCase(edtSearch.Text);
  if not FindChild(tv.Selected, sSearchText) then
    FindParent(tv.Selected, sSearchText);
end;

procedure TFrmWindowView.edtSearchKeyPress(Sender: TObject; var Key: Char);
//按回车查找
begin
  if Key = #13 then
  begin
    Key :=  #0;
    btnSearch.Click;
  end;
end;

procedure TFrmWindowView.SelectLanguage(Sender: TObject);
//语言菜单动作
begin
  if Sender is TMenuItem then
  begin
    GlobalOption.Language  :=  TMenuItem(Sender).Hint;
    Self.LanguageFile   :=  GlobalOption.Language;
    //GlobalOption.LoadLanguage(Self, TMenuItem(Sender).Hint);
  end;  
end;

procedure TFrmWindowView.ToolsExecute(Sender: TObject);
//工具菜单动作
begin
  inherited;
  case TComponent(Sender).Tag of
    1 :
      begin
        Screen.Cursor :=  crHourGlass;
        try
          TFrmProcessManage.Create(Self).ShowModal;
        finally
          Screen.Cursor :=  crDefault;
        end;
      end;
  end;
end;

procedure TFrmWindowView.pmActionsPopup(Sender: TObject);
//更改Action的可见性
var
  b : Boolean;
  i : Integer;
  Style : Longint;
begin
  inherited;
  if not Assigned(tv.Selected) or not Assigned(tv.Selected.Data) then
  begin
    for i := 0 to pmActions.Items.Count - 1 do
      if Assigned(pmActions.Items[i].Action) then
        TAction(pmActions.Items[i].Action).Enabled  :=  False;
    Exit;
  end
  else begin
    for i := 0 to pmActions.Items.Count - 1 do
      if Assigned(pmActions.Items[i].Action) then
        TAction(pmActions.Items[i].Action).Enabled  :=  True;
  end;
  b :=  CheckNodeData;
  case PHandleInfo(tv.Selected.Data).HandleType of
    Window    :
      begin
        acEnable.Visible  :=  True;
        acDisable.Visible :=  True;
        acShow.Visible    :=  True;
        acHide.Visible    :=  True;
        acDelete.Visible  :=  True;
        acExpandMenu.Visible  :=  True;

        acEnable.Enabled  :=  b;
        acDisable.Enabled :=  b;
        acShow.Enabled    :=  b;
        acHide.Enabled    :=  b;
        acDelete.Enabled  :=  b;//}

        Style :=  GetWindowLong(PHandleInfo(tv.Selected.Data).HWnd, GWL_STYLE);
        acExpandMenu.Enabled  :=  IsWindowVisible(PHandleInfo(tv.Selected.Data).HWnd)
            and (Style and WS_SYSMENU > 0)
            and (Style and (WS_CHILD or WS_CHILDWINDOW) = 0);
      end;
    MainMenu  :
      begin
        acEnable.Visible  :=  False;
        acDisable.Visible :=  False;
        acShow.Visible    :=  False;
        acHide.Visible    :=  False;
        acDelete.Visible  :=  False;
        acExpandMenu.Visible  :=  False;
      end;
    MenuItem  :
      begin
        acShow.Visible    :=  False;
        acHide.Visible    :=  False;
        acExpandMenu.Visible  :=  False;

        acEnable.Visible  :=  True;
        acDisable.Visible :=  True;
        acDelete.Visible  :=  True;
        acEnable.Enabled  :=  b;
        acDisable.Enabled :=  b;
        acDelete.Enabled  :=  b;//}
      end;
  end;
end;

procedure TFrmWindowView.acAboutUpdate(Sender: TObject);
begin
  inherited;
  panCapture.Caption    :=  acCapture.Caption;
  panCapture.Hint       :=  acCapture.Hint;
  panCapture.Font.Name  :=  Font.Name;
end;

procedure TFrmWindowView.acShowWindowExecute(Sender: TObject);
//显示窗口
begin
  inherited;
  if Self.Showing then
  begin
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
  end
  else begin
    TrayIcon.ShowMainForm;
    SetForegroundWindow(Handle);
  end;
end;

procedure TFrmWindowView.WMSysCommand(var Message: TWMSysCommand);
//处理消息
begin
  case Message.CmdType of
    SC_MINIMIZE :
      begin
        //最小化
        inherited;
        TrayIcon.HideMainForm;
      end;
    else
      inherited;
  end;
end;

procedure TFrmWindowView.tmeMemoryTimer(Sender: TObject);
//交换内存到虚拟内存
var
  PMC: PPROCESS_MEMORY_COUNTERS;
  hPID: HWND;
  l: DWORD;
begin
  inherited;
  SetProcessWorkingSetSize(GetCurrentProcess, $FFFF, $1FFFFF);
  hPID:= GetCurrentProcess;
  new(PMC);
  try
    l:= SizeOf(PMC^);
    ZeroMemory(PMC, l);
    GetProcessMemoryInfo(hPID, PMC, l);
    staBar.Panels[1].Text :=  FormatFloat('内存占用: #,##0 K', PMC^.WorkingSetSize div 1024);
  finally
    dispose(PMC);
  end;
end;

procedure TFrmWindowView.staBarResize(Sender: TObject);
//调整状态条位置
begin
  inherited;
  staBar.Panels[0].Width  :=  staBar.Width - 150;
end;

procedure TFrmWindowView.tmeInvertTrackerTimer(Sender: TObject);
//定时闪烁边框
begin
  inherited;
  if (FInvertTrackerCount > 0) and (FInvertTrackerHandle > 0) then
  begin
    InvertTracker(FInvertTrackerHandle);
    FInvertTrackerStatus  :=  not FInvertTrackerStatus;
    if not FInvertTrackerStatus then
    begin
      Dec(FInvertTrackerCount);
      if  FInvertTrackerCount = 0 then
        tmeInvertTracker.Enabled  :=  False;
    end;
  end;
end;

procedure TFrmWindowView.InvertTrackerNode(const ANode  : TTreeNode);
//闪烁边框
begin
  ResetLastInvertTrackerHandle;
  if Assigned(ANode) and Assigned(ANode.Data) then
    if PHandleInfo(ANode.Data).HandleType = window then
    begin
      FInvertTrackerHandle  :=  PHandleInfo(ANode.Data).HWnd;
      FInvertTrackerCount := 3;
      tmeInvertTracker.Enabled  :=  True;
      tmeInvertTracker.OnTimer(tmeInvertTracker);
    end;
end;

procedure TFrmWindowView.ResetLastInvertTrackerHandle;
//重置前一个边框
begin
  if FInvertTrackerStatus then
  begin
    InvertTracker(FInvertTrackerHandle);
    FInvertTrackerStatus  :=  False;
    FInvertTrackerCount   :=  0;
    FInvertTrackerHandle  :=  0;
  end;
  tmeInvertTracker.Enabled  :=  False;
end;

procedure TFrmWindowView.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  ResetLastInvertTrackerHandle;
end;

function TFrmWindowView.CheckNodeData : Boolean;
var
  OutInfo : string;
begin
  inherited;
  OutInfo :=  '';
  Result  :=  False;
  if not IsCapture and Assigned(tv.Selected) and Assigned(tv.Selected.Data) then
  begin
    Result  :=  CheckHandle(PHandleInfo(tv.Selected.Data), OutInfo);
    staBar.Panels[0].Text :=  OutInfo;
  end;
end;

end.

