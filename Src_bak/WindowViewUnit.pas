//==============================================================================
// Unit Name: WindowViewUnit
// Author   : ysai
// Date     : 2003-11-28
// Purpose  :
// History  :
//==============================================================================

unit WindowViewUnit;

interface

uses
  Windows, SysUtils, Classes, Forms,Graphics,ShellAPI,TLHelp32,psapi,
  StrUtils,Variants,Messages,IniFiles,ExtCtrls,Controls,TypInfo;

resourcestring
  S_Menu          = 'Menu';
  S_AppName       = 'Window View Tool';
  S_Null          = '(Null)';
  S_About         = '&About...';
  S_Warning       = 'Warning';
  S_Confirm       = 'Confirm';
  S_Error         = 'Error';
  S_Information   = 'Information';

const
  SCaption        = 'Caption';
  SHint           = 'Hint';

  SIniAppName     = 'Window View Tools';
  SIniLanguage    = 'Language';
  SIniAutoHide    = 'AutoHide';
  SIniStayOnTop   = 'StayOnTop';
  SIniState       = 'State';
  SIniTop         = 'Top';
  SIniLeft        = 'Left';
  SIniWidth       = 'Width';
  SIniHeight      = 'Height';
  SLanguageName   = 'LanguageName';

  //边框宽度
  BORDER_WIDTH    = 2;

  //自定义消息,关于菜单
  UM_ABOUT  = WM_USER+400;

type
  THandleType = (Window,MainMenu,MenuItem,ToolButton);

  PWindowInfo = ^TWindowInfo;
  TWindowInfo = record
    Enabled     : Boolean;
    IsWindow    : Boolean;
    Text        : String;
    ClassName   : String;
    Top         : Integer;
    Left        : Integer;
    Height      : Integer;
    Width       : Integer;
  end;

  PMenuItemInfo = ^TMenuItemInfo;
  TMenuItemInfo = record
    Caption     : String;
    SubMenu     : Boolean;
    Index       : Integer;
    Command     : Integer;
  end;

  PToolButtonInfo = ^TToolButtonInfo;
  TToolButtonInfo = record
    Caption     : string;
    Command     : Integer;
  end;

  PHandleInfo = ^THandleInfo;
  THandleInfo = record
    HWnd        : HWnd;
    HandleType  : THandleType;
    HandleInfo  : Pointer;
  end;

  PProcessInfo = ^TProcessInfo;
  TProcessInfo = Record
    ExeFile    : String;
    ProcessID  : DWORD;
  end;

  TFormState  = record
    Top     : Integer;
    Left    : Integer;
    Width   : Integer;
    Height  : Integer;
    State   : TWindowState
  end;

  TGlobalOption  = class(TComponent)
  private
    FApplicationPath  : String;
    FIniFileName      : String;

    FsLanguage         : string;
    FbAutoHide        : Boolean;
    FbStayOnTop       : Boolean;
    procedure AppException(Sender: TObject; E: Exception);
  public
    property IniFileName    : string  read FIniFileName Write FIniFileName;
    property Language       : string  read FsLanguage write FsLanguage;
    property bAutoHide      : Boolean read FbAutoHide write FbAutoHide;
    property bStayOnTop     : Boolean read FbStayOnTop write FbStayOnTop;

    constructor Create(AOwner: TComponent);reintroduce;override;
    destructor Destroy; override;
    procedure LoadOptions; virtual;
    procedure SaveOptions; virtual;
  end;

  TPanelEx  = class(TPanel)
  private
    procedure WMLButtonDown(var Message:TMessage);message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message:TMessage);message WM_LBUTTONUP;
    procedure CMMouseEnter(var Message:TMessage);message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message:TMessage);message CM_MOUSELEAVE;
  public
    property Canvas;
  end;

function AddAboutMenu(
    const Handle  : HWND
    ):boolean;

function ShowAbout: boolean;

function MsgBox(
    const AMsg    : Variant;
    const ATitle  : string='';
    const AFlag   : longint=0;
    const AHandle : HWND=0
    ):integer;

function GetWindowInfo(
    const AHwnd : HWnd
    ):PWindowInfo;

function GetSubMenuItemInfo(
    const AHwnd     : Hwnd;
    const Position  : Integer
    ):PMenuItemInfo;

function GetClassName(
    const HWnd  : HWnd
    ):string;

function GetWindowText(
    const HWnd        : HWnd;
    const GetPassWord : Boolean = False
    ):string;

function HookWindow(
    const AOwner  : HWND;
    const AHandle : HWND
    ):Boolean;

{function LoadSetting:boolean;
function SaveSetting:boolean;}

//procedure SetLanguage(ALanguage:TLanguage=English);

procedure InvertTracker(
    const hwndDest: HWND
    );

//function EnableDebugPrivilege:Boolean;
function GetLastErrorText: string;

procedure EnumProcess(
    const AList : TList
    );

procedure KillProcess(
    const dwProcessId: DWORD
    );

function IsWindowEx(
    const AHWND : HWND
    ):Boolean;

function CheckHandle(
    const AHandleInfo : PHandleInfo;
    var   OutInfo : string
    ):Boolean;

//载入语言包
function LoadLanguageFromFile(
    const AComponent  : TComponent;
    const AFileName   : string  = ''
    ):boolean;

var
  GlobalOption       : TGlobalOption;
  SAppName        : string;
  SMenu           : string;
  SNull           : string;
  SAbout          : string;
  SWarning        : string;
  SConfirm        : string;
  SError          : string;
  SInformation    : string;

  //FCount  : Integer;

implementation

function AddAboutMenu(
    const Handle  : HWND
    ):boolean;
//增加关于菜单
var
  SysMenu : HMenu;
  i       : integer;
  s       : array[0..MAXBYTE] of char;
begin
  SysMenu :=  GetSystemMenu(Handle, False);
  i       :=  GetMenuItemCount(SysMenu)-1;
  InsertMenu(SysMenu, i, MF_BYPOSITION+MF_SEPARATOR, 0, nil);
  InsertMenu(SysMenu, i, MF_BYPOSITION, UM_ABOUT, PChar(SAbout));
  GetMenuString(SysMenu, i-1, s, MAXBYTE, MF_BYPOSITION);
  if s[0]<>#0 then
    InsertMenu(SysMenu, i, MF_BYPOSITION+MF_SEPARATOR, 0, nil);
  result  :=  true;
end;

function ShowAbout: boolean;
//显示关于
var
  hIcon, hInst:integer;
begin
  hInst   :=  GetWindowWord(Application.Handle, GWL_HINSTANCE);
  hIcon   :=  ExtractIcon(hInst, PChar(Application.ExeName), 0);
  Result  :=  Boolean(ShellAbout(GetActiveWindow, 
    PChar(SAppName), PChar(SAppName), hIcon));
end;

{function DelAboutMenu(Handle:THandle):boolean;
//删除关于菜单
var
  SysMenu : HMenu;
  i       : integer;
  s       : array[0..MAXBYTE] of char;
begin
  SysMenu :=  GetSystemMenu(Handle, False);
  i       :=  GetMenuItemCount(SysMenu) - 2;
  GetMenuString(SysMenu, i, s, MAXBYTE, MF_BYPOSITION);
  if StrPas(s)=AOptions.SAbout then
  begin
    DeleteMenu(SysMenu, i, MF_BYPOSITION);
    GetMenuString(SysMenu, i, s, MAXBYTE, MF_BYPOSITION);
    if s[0]=#0 then
      DeleteMenu(SysMenu, i, MF_BYPOSITION);
  end;
  result  :=  true;
end;}

function MsgBox(
    const AMsg    : Variant;
    const ATitle  : string='';
    const AFlag   : longint=0;
    const AHandle : HWND=0
    ):integer;
//简化MessageBox函数
//返回用户的选择,与Application.MessageBox相同
var
  h     : HWND;
  Flag  : Longint;
  Title : String;
begin
  if (AFlag=0) or (AFlag=MB_OK) then
    Flag:=MB_OK + MB_ICONINFORMATION
  else
    Flag:=AFlag;
  if length(ATitle)=0 then
  begin
    if MB_ICONWARNING and AFlag = MB_ICONWARNING then
      Title :=  SWarning
    else if MB_ICONQUESTION and AFlag = MB_ICONQUESTION then
      Title :=  SConfirm
    else if MB_ICONSTOP and AFlag = MB_ICONSTOP then
      Title :=  SError
    else
      Title := SInformation;;
  end else
    Title :=  ATitle;
  if AHandle=0 then
    if Assigned(Screen.ActiveForm) then
      h :=  Screen.ActiveForm.Handle
    else
      h :=  GetActiveWindow
  else
    h :=  AHandle;
  Result  :=  MessageBox(h, PChar(VarToStr(AMsg)), PChar(Title), Flag);
end;

function GetWindowInfo(
    const AHwnd : HWnd
    ):PWindowInfo;
//取得窗口信息结构
var
  rt  : TRect;
  p : TPoint;
  hParent : HWND;
begin
  New(Result);
  with Result^ do
  begin
    Enabled   :=  IsWindowEnabled(AHWnd);
    IsWindow  :=  IsWindowEx(AHwnd);
    Text      :=  GetWindowText(AHWnd, True);
    if Text='' then Text  :=  SNull;
    ClassName :=  GetClassName(AHWnd) + ' ('+ IntToStr(AHwnd) +')';
    GetWindowRect(AHwnd, rt);
    hParent :=  GetParent(AHwnd);
    if hParent > 0 then
    begin
      p.X :=  rt.Left;
      p.Y :=  rt.Top;
      ScreenToClient(hParent, p);
      Left  :=  p.X;
      Top :=  p.Y;
    end
    else begin
      Top   :=  rt.Top;
      Left  :=  rt.Left;
    end;
    Width :=  rt.Right - rt.Left;
    Height  :=  rt.Bottom - rt.Top;
  end;
end;

function GetSubMenuItemInfo(
  const AHwnd     : Hwnd;
  const Position  : Integer
  ):PMenuItemInfo;
//取得菜单信息
var
  psCaption : array[0..MAXBYTE] of char;
  mf        : tagMENUITEMINFO;
begin
  New(Result);
  GetMenuString(AHwnd, Position, psCaption, MAXBYTE, MF_BYPOSITION);
  GetMenuItemInfo(AHwnd, Position, True, mf);
  with Result^ do
  begin
    Command :=  GetMenuItemID(AHwnd, Position);
    Index   :=  Position;
    Caption :=  psCaption;
    if Caption='' then Caption  :=  SNull;
    //bEnabled  :=  (mf.fState and not (MFS_DISABLED or MFS_GRAYED))=0;
  end;
end;

function GetClassName(
    const HWnd  : HWnd
    ):String;
//取得句柄的类名
var
  psText    : array[0..MAXBYTE] of char;
begin
  if HWnd = 0 then
    Result  :=  ''
  else begin
    Windows.GetClassName(HWnd, psText, MAXBYTE);
    Result  :=  psText;
  end;
end;

function GetWindowText(
    const HWnd        : HWnd;
    const GetPassWord : Boolean = False
    ):string;
//取得文本且可以取得密码
var
  iPwdChar  : Integer;
  iPwdLast  : Integer;
  psText    : array[0..MAXBYTE] of char;
  i         : Integer;
//  lRes      : Cardinal;
begin
  Result  :=  '';
  if Hwnd = 0 then Exit;
  iPwdChar:=SendMessage(HWnd, EM_GETPASSWORDCHAR, 0, 0);
  if (iPwdChar<>0) and GetPassWord then
  begin
    iPwdLast  :=  0;
    i         :=  0;

    {SendMessageTimeout(HWnd, EM_SETPASSWORDCHAR, 0, 0, SMTO_ABORTIFHUNG, 100, lRes);
    sleep(10);
    iPwdLast:=SendMessage(HWnd, EM_GETPASSWORDCHAR, 0, 0);
    //}
    //{
    while iPwdLast=0 do
    begin
      PostMessage(HWnd, EM_SETPASSWORDCHAR, 0, 0);
      Application.ProcessMessages;
      Inc(i);
      iPwdLast:=SendMessage(HWnd, EM_GETPASSWORDCHAR, 0, 0);
      if i>100 then break;
    end ;
    //}

    SendMessage(HWnd, WM_GETTEXT, MAXBYTE, Longint(@psText));
    Result  :=  psText;
    SendMessage(HWnd, EM_SETPASSWORDCHAR, iPwdChar, 0);
  end else begin
    SendMessage(HWnd, WM_GETTEXT, MAXBYTE, Longint(@psText));
    Result  :=  psText;
  end;
  //if Result = '' then Result  :=  SNull;
end;

procedure InvertTracker(
    const hwndDest: HWND
    );
//画边框
var
  hdcDest   : HWND;
  hPen      : HWND;
  hOldPen   : HWND;
  hOldBrush : HWND;
  cr        : HWND;
  rc        : TRect;
begin
  GetWindowRect(hwndDest, rc);
  hdcDest := GetWindowDC(hwndDest);
  SetROP2(hdcDest, R2_NOT);
  cr    := clBlack;
  hPen  := CreatePen(PS_INSIDEFRAME, BORDER_WIDTH, cr);

  hOldPen   := SelectObject(hdcDest, hPen);
  hOldBrush := SelectObject(hdcDest, GetStockObject(NULL_BRUSH));
  Rectangle(hdcDest, 0, 0, rc.Right - rc.Left, rc.Bottom - rc.Top);
  SelectObject(hdcDest, hOldBrush);
  SelectObject(hdcDest, hOldPen);

  ReleaseDC(hwndDest, hdcDest);
  DeleteObject(hPen);
end;

function EnableDebugPrivilege:Boolean;
//获得DEBUG权限
var
  hToken    : THandle;
  tp        : TTokenPrivileges;
  TPPrev    : TTokenPrivileges;
  dwRetLen  : DWORD;
begin
  Result  :=  False;
	if not OpenProcessToken(
      GetCurrentProcess,
      TOKEN_ADJUST_PRIVILEGES or TOKEN_ALL_ACCESS or TOKEN_QUERY,
      hToken) then Exit;
  tp.PrivilegeCount := 1;
  if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', tp.Privileges[0].Luid)
      then Exit;
  tp.Privileges[0].Attributes :=SE_PRIVILEGE_ENABLED;
  dwRetLen := 0;
  Result  :=
      AdjustTokenPrivileges(hToken, FALSE, tp, sizeof(TPPrev), TPPrev, dwRetLen);
  //Result  :=  GetLastError <> ERROR_SUCCESS;
  CloseHandle(hToken);
end;//}

procedure EnumProcess(const AList : TList);
//枚举进程

  function  GetExePathByProcessID(PID: DWord): String;
  var
    snap  : THandle;
    me32  : TMODULEENTRY32;
  begin
    snap := 0;
    result := '';
    try
      snap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, PID);
      if snap <> 0 then
      begin
        me32.dwSize:= SizeOf(TMODULEENTRY32);
        if Module32First(snap, me32) then
        begin
          if me32.th32ProcessID = PID then
          begin
            Result  := me32.szExePath;
            exit;
          end else
          while Module32Next(snap, me32) do
          if me32.th32ProcessID = PID then
          begin
            Result  := me32.szExePath;
            break;
          end;
        end;
      end;
    finally
      CloseHandle(snap);
    end;
  end;//}

  {function  GetExePathByProcessID(PID: DWord): String;
  var
    h :  THandle;
    FileName  : string;
    iLen  : integer;
    hMod  : HMODULE;
    cbNeeded:DWORD;
  begin
    Result  :=  '';
    h  :=  OpenProcess(PROCESS_ALL_ACCESS,  False, PID);
    if h > 0 then
    begin
      if EnumProcessModules(h, @hMod, SizeOf(hMod), cbNeeded) then
      begin
        SetLength(FileName, MAX_PATH);
        iLen  :=  GetModuleFileNameEx(h, hMod, PChar(FileName), MAX_PATH);
        if iLen <> 0 then
        begin
          SetLength(FileName, StrLen(PChar(FileName)));
          Result  :=  FileName;
        end;
      end;
    end;
  end;//}

var
  p               : PProcessInfo;
  ContinueLoop    : BOOL;
  FSnapshotHandle : THandle;
  FProcessEntry32 : TProcessEntry32;
begin
  FSnapshotHandle         :=  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    FProcessEntry32.dwSize  :=  Sizeof(FProcessEntry32);
    ContinueLoop            :=  Process32First(FSnapshotHandle, FProcessEntry32);
    while integer(ContinueLoop)<>0 do
    begin
      New(p);
      p.ProcessID   := FProcessEntry32.th32ProcessID;
      p.ExeFile     := GetExePathByProcessID(p.ProcessID);
      if p.ExeFile = '' then
        p.ExeFile :=  FProcessEntry32.szExeFile;
      AList.Add(p);
      ContinueLoop  :=  Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
  finally
    CloseHandle(FSnapshotHandle);
  end;
end;

procedure KillProcess(
    const dwProcessId: DWORD
    );
//杀进程
var
  ProcHandle: THandle;
begin
  ProcHandle := OpenProcess(1, FALSE, dwProcessID);
  try
    if ProcHandle <> 0 then
    begin
      if TerminateProcess(ProcHandle, $FFFFFFFF) then
        WaitForSingleObject(ProcHandle, INFINITE);
    end;
  finally
    CloseHandle(ProcHandle);
  end;
end;

function IsWindowEx(
    const AHWND : HWND
    ):Boolean;
//判断是否是Window
var
  hStyle  : HWND;
begin
  Result  :=  False;
  if not IsWindow(AHWND) then Exit;
  hStyle :=  GetWindowLong(AHWND, GWL_STYLE);
  Result  :=
      (hStyle and WS_SYSMENU = WS_SYSMENU)
      or (hStyle and WS_POPUP = WS_POPUP);
end;

function GetLastErrorText: string;
var
  dwSize: DWORD;
  lpszTemp: LPSTR;
begin
  dwSize := 512;
  lpszTemp := nil;
  try
    GetMem(lpszTemp, dwSize);
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY,
      nil, GetLastError, LANG_NEUTRAL, lpszTemp, dwSize, nil);
  finally
    Result := StrPas(lpszTemp);
    FreeMem(lpszTemp);
  end;
end;

function CheckHandle(
    const AHandleInfo : PHandleInfo;
    var   OutInfo : string
    ):Boolean;
begin
  Result  :=  False;
  case AHandleInfo.HandleType of
    Window  :
      begin
        Result  :=  GetWindowLong(AHandleInfo.HWnd, GWL_STYLE) <> 0;
      end;
    MainMenu  {:
      begin
        Result  :=  GetMenuItemCount(HMENU(AHandleInfo.HWnd)) >= 0;
      end;  //},
    MenuItem  :
      begin
        Result  :=  IsMenu(HMENU(AHandleInfo.HWnd));
      end;
    ToolButton  :
      begin
      end;
  end;
  if not Result then
  begin
    OutInfo :=  GetLastErrorText;
  end;
end;

{ TPanelEx }

procedure TPanelEx.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  BevelOuter  :=  bvRaised;
end;

procedure TPanelEx.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  BevelOuter  :=  bvNone;
end;

procedure TPanelEx.WMLButtonDown(var Message: TMessage);
begin
  inherited;
  BevelOuter  :=  bvLowered;
end;

procedure TPanelEx.WMLButtonUp(var Message: TMessage);
begin
  inherited;
  BevelOuter  :=  bvNone;
end;

{ TOptions }

constructor TGlobalOption.Create(AOwner: TComponent);
//初始化,取出设置
begin
  FApplicationPath  :=  ExtractFilePath(Application.ExeName);
  FIniFileName      :=  ChangeFileExt(Application.ExeName, '.ini');
  inherited;
  Application.OnException :=  AppException;
  LoadOptions;
end;

destructor TGlobalOption.Destroy;
//释放前保存设置
begin
  SaveOptions;
  inherited;
end;

procedure TGlobalOption.LoadOptions;
//取出设置
begin
  if not FileExists(FiniFileName) then Exit;
  with TIniFile.Create(FIniFileName) do
  begin
    fsLanguage  :=  ReadString(SIniAppName, SIniLanguage, '');
    fbAutoHide  :=  ReadBool(SIniAppName, SIniAutoHide, False);
    fbStayOnTop :=  ReadBool(SIniAppName, SIniStayOnTop, False);
  end;//with
end;

procedure TGlobalOption.SaveOptions;
//保存设置
begin
  with TIniFile.Create(FIniFileName) do
  begin
    WriteString (SIniAppName, SIniLanguage,   FsLanguage);
    WriteBool   (SIniAppName, SIniAutoHide,   FbAutoHide);
    WriteBool   (SIniAppName, SIniStayOnTop,  FbStayOnTop);
  end;  //with
end;

{function LoadSetting:Boolean;
//从注册表读取保存的设置
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    with Reg do
    begin
      RootKey:=HKEY_LOCAL_MACHINE;
      if OpenKey(SREGSubKey+SRegAppName, True) then
      begin
        if ValueExists(SRegLanguage)  then Language   :=TLanguage(ReadInteger(SRegLanguage));
        if ValueExists(SRegAutoHide)  then bAutoHide  :=ReadBool(SRegAutoHide);
        if ValueExists(SRegStayOnTop) then bStayOnTop :=ReadBool(SRegStayOnTop);
        if ValueExists(SRegTop)       then iTop       :=ReadInteger(SRegTop);
        if ValueExists(SRegLeft)      then iLeft      :=ReadInteger(SRegLeft);
        if ValueExists(SRegWidth)     then iWidth     :=ReadInteger(SRegWidth);
        if ValueExists(SRegHeight)    then iHeight    :=ReadInteger(SRegHeight);
        CloseKey;
      end;  //if
    end;//with
    result:=true;
  finally
    Reg.Free;
  end;
end;}

{function SaveSetting:Boolean;
//保存当前设置到注册表
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    with Reg do
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      if OpenKey(SREGSubKey+SRegAppName, True) then
      begin
        WriteInteger(SRegLanguage,  Integer(Language));
        WriteBool   (SRegAutoHide,  bAutoHide);
        WriteBool   (SRegStayOnTop, bStayOnTop);
        WriteInteger(SRegTop,       iTop);
        WriteInteger(SRegLeft,      iLeft);
        WriteInteger(SRegWidth,     iWidth);
        WriteInteger(SRegHeight,    iHeight);
        CloseKey;
      end;  //if
    end;//with
    result:=true;
  finally
    Reg.Free;
  end;
end;}

procedure TGlobalOption.AppException(Sender: TObject; E: Exception);
begin
  MsgBox(e.Message, '', MB_ICONSTOP);
  Abort;
end;

function LoadLanguageFromFile(
    const AComponent  : TComponent;
    const AFileName   : string  = ''
    ):boolean;
//设置语言

  function PropertyExists(
      const AObject   : TObject;
      const APropName : String
      ):Boolean;
  //判断一个属性是否存在
  var
    PropInfo:PPropInfo;
  begin
    PropInfo:=GetPropInfo(AObject.ClassInfo, APropName);
    Result:=Assigned(PropInfo);
  end;

  function SetStringPropertyIfExists(
      const AObject   : TObject;
      const APropName : string;
      const AValue    : string
      ):Boolean;
  //给字符串属性赋值, 如果存在
  var
    PropInfo:PPropInfo;
  begin
    PropInfo:=GetPropInfo(AObject.ClassInfo, APropName);
    if Assigned(PropInfo) and
        (PropInfo.PropType^.Kind in [tkString, tkLString, tkWString]) then
    begin
      SetStrProp(AObject, PropInfo, AValue);
      Result:=True;
    end else
      Result:=False;
  end;

  function GetStringProperty(
      const AObject   : TObject;
      const APropName : string
      ):String;
  //取得字符串属性值
  var
    PropInfo:PPropInfo;
  begin
    Result  :=  '';
    PropInfo:=GetPropInfo(AObject.ClassInfo, APropName);
    if Assigned(PropInfo) and
        (PropInfo^.PropType^.Kind in [tkString, tkLString, tkWString]) then
      Result  :=  GetStrProp(AObject, PropInfo);
  end;

  function SetIntegerPropertyIfExists(
      const AObject   : TObject;
      const APropName : string;
      const AValue    : integer
      ):Boolean;
  //给整型属性赋值,如果存在
  var
    PropInfo:PPropInfo;
  begin
    PropInfo:=GetPropInfo(AObject.ClassInfo, APropName);
    if Assigned(PropInfo) and
        (PropInfo^.PropType^.Kind = tkInteger) then
    begin
      SetOrdProp(AObject, PropInfo,AValue);
      Result:=True;
    end else
      Result:=False;
  end;

  function GetObjectProperty(
      const AObject   : TObject;
      const APropName : string
      ):TObject;
  var
    PropInfo:PPropInfo;
  begin
    Result  :=  nil;
    PropInfo:=GetPropInfo(AObject.ClassInfo, APropName);
    if Assigned(PropInfo) and
        (PropInfo^.PropType^.Kind = tkClass) then
      Result  :=  GetObjectProp(AObject, PropInfo);
  end;

var
  i         : Integer;
  s         : string;
begin
  Result  :=  False;
  if not FileExists(AFileName) then Exit;
  with TIniFile.Create(AFileName) do
  try
    //读取变量
    SAppName        :=  ReadString(SIniLanguage, 'AppName', S_AppName);
    SMenu           :=  ReadString(SIniLanguage, 'Menu', S_Menu);
    SNull           :=  ReadString(SIniLanguage, 'Null', S_Null);
    SAbout          :=  ReadString(SIniLanguage, 'About', S_About);
    SWarning        :=  ReadString(SIniLanguage, 'Warning', S_Warning);
    SConfirm        :=  ReadString(SIniLanguage, 'Confirm', S_Confirm);
    SError          :=  ReadString(SIniLanguage, 'Error', S_Error);
    SInformation    :=  ReadString(SIniLanguage, 'Information', S_Information);

    if PropertyExists(AComponent, 'Font') then
    begin
      s :=  ReadString(SIniLanguage, 'FontName', '');
      i :=  ReadInteger(SIniLanguage, 'FontSize', 0);
      if s <> '' then
        SetStringPropertyIfExists(
            GetObjectProperty(AComponent, 'Font'), 'Name', s);
      if i > 0 then
        SetIntegerPropertyIfExists(
            GetObjectProperty(AComponent, 'Font'), 'Size', i);
    end;

    //设置Caption
    if PropertyExists(AComponent, SCaption) then
    begin
      s :=  ReadString(AComponent.Name, SCaption, '');
      if s<>'' then
        SetStringPropertyIfExists(AComponent, SCaption, s);
    end;

    for i :=  0 to AComponent.ComponentCount - 1 do
    begin
      //设置Caption
      if PropertyExists(AComponent.Components[i], SCaption) then
      begin
        s :=  ReadString(AComponent.Name,
            AComponent.Components[i].Name + '.' + SCaption, '');
        if s <> '' then
          SetStringPropertyIfExists(AComponent.Components[i], SCaption, s);
      end;
      //设置Hint
      if PropertyExists(AComponent.Components[i], SHint) then
      begin
        s :=  ReadString(AComponent.Name,
            AComponent.Components[i].Name+'.'+SHint, '');
        if s<>'' then
          SetStringPropertyIfExists(AComponent.Components[i], SHint, s);
      end;
    end;
    Result  :=  True;
  finally
    Free;
  end;
end;

function HookWindow(
    const AOwner  : HWND;
    const AHandle : HWND
    ):Boolean;
var
  hModule : THandle;
  HookWindowMenu: function (
      const AOwner : HWND;
      const AHandle : HWND
      ):Boolean; stdcall;
const
  SHookFile : PChar = 'WindowExp.dll';
  SFunc_HookMenu  : PChar = 'HookWindowMenu';
begin
  Result  :=  False;
  if FileExists(SHookFile) then
  begin
    hModule :=  LoadLibrary(SHookFile);
    if hModule > 0 then
    begin
      @HookWindowMenu :=  GetProcAddress(hModule,  SFunc_HookMenu);
      if Assigned(HookWindowMenu) then
      try
        Result  :=  HookWindowMenu(AOwner, AHandle);
      except
      end;
    end;
  end;
  //if Result then
  //  Inc(FCount);
end;

function UnHookWindow : Boolean;
var
  hModule : THandle;
  UnHookAllWindowMenu: function :Boolean; stdcall;
const
  SHookFile : PChar = 'WindowExp.dll';
  SFunc_HookMenu  : PChar = 'UnHookAllWindowMenu';
begin
  Result  :=  False;
  if FileExists(SHookFile) then
  begin
    hModule :=  LoadLibrary(SHookFile);
    if hModule > 0 then
    begin
      @UnHookAllWindowMenu :=  GetProcAddress(hModule, SFunc_HookMenu);
      if Assigned(UnHookAllWindowMenu) then
      try
        Result  :=  UnHookAllWindowMenu;
      except
      end;
    end;
  end;
end;

initialization
  //初始化
  GlobalOption    :=  TGlobalOption.Create(Application);
  SAppName        :=  S_AppName;
  SMenu           :=  S_Menu;
  SNull           :=  S_Null;
  SAbout          :=  S_About;
  SWarning        :=  S_Warning;
  SConfirm        :=  S_Confirm;
  SError          :=  S_Error;
  SInformation    :=  S_Information;
  EnableDebugPrivilege;

finalization
  UnHookWindow;

end.
