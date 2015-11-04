unit WindowExpHook;

interface

uses
  SysUtils, windows, Messages, Graphics, Clipbrd;

const
  SMsg_WEH_Hook     = '{557F4F7F-2AE2-4902-B8AA-65A609EA5408}';
  SMsg_WEH_UnHook   = '{75CE5BA2-4479-4CEA-AEA7-E61BD2DBDF22}';
  SMsg_WEH_GetText  = '{8551C8FA-715F-47F8-94FA-9EA592459401}';

type
  PWindowHookInfo = ^TWindowHookInfo;
  TWindowHookInfo = record
    Handle  : HWND;
    OldProc : Pointer;
    Separator : Boolean;
    SubMenu : HMENU;
  end;

  PWindowExpHookData  = ^TWindowExpHookData;
  TWindowExpHookData  = record
    hWindowHandle   : HWND;
    hHookMessage    : Longword;
    hUnHookMessage  : Longword;
    hGetTextMessage : Longword;
    Hooks : array[0..99] of TWindowHookInfo;
  end;

function HookWindowMenu(
    const AOwner  : HWND;
    const AHandle : HWND
    ):Boolean;stdcall;
function UnHookAllWindowMenu:Boolean;stdcall;

var
  WEHData : PWindowExpHookData;

implementation

uses
  WindowExpRes, ShellAPI;

const
  UM_TOPMOST      = WM_USER + $0101;
  UM_PRINTSCREEN  = WM_USER + $0102;
  UM_TRANSPARENT  = WM_USER + $0103;
  UM_SIZE         = WM_USER + $0104;
  UM_ABOUT        = WM_USER + $0110;

function GetHookInfo(
    const AHandle : HWND
    ):PWindowHookInfo;
//取得一个结构
var
  i : Integer;
begin
  Result  :=  nil;
  for i := Low(WEHData.hooks) to High(WEHData.Hooks) do
    if WEHData.Hooks[i].Handle = AHandle then
    begin
      Result  :=  @WEHData.Hooks[i];
      break;
    end;
end;

function GetEmptyHookInfo : PWindowHookInfo;
//取得空闲的结构
var
  i : Integer;
begin
  Result  :=  nil;
  for i := Low(WEHData.hooks) to High(WEHData.Hooks) do
  begin
    if not IsWindow(WEHData.Hooks[i].Handle) then
      WEHData.Hooks[i].Handle :=  0;
    if 0 = WEHData.Hooks[i].Handle then
    begin
      Result  :=  @WEHData.Hooks[i];
      break;
    end;
  end;
end;

function ShowAbout(const pwhi  : PWindowHookInfo): boolean;
//显示关于
//var
//  hIcon,hInst:integer;
begin
  //hInst :=  HINSTANCE;
  //hInst   :=  GetWindowWord(Application.Handle,GWL_HINSTANCE);
  //hIcon   :=  ExtractIcon(hInst,PChar(Application.ExeName),0);
  Result  :=  Boolean(ShellAbout(pwhi.Handle,
    'WindowView','WindowView 0.1',0));
end;

procedure WindowProc(
    Handle  : HWND;   // handle of window
    Msg     : Longword;   // message identifier
    wParam  : wParam; // first message parameter
    lParam  : lParam  // second message parameter
    );stdcall;
//窗口回调过程

  procedure UpdateTopMost(const pwhi  : PWindowHookInfo);
  //设置是否最上
  var
    bChecked  : Boolean;
  begin
    bChecked  :=  GetMenuState(pwhi.SubMenu, UM_TOPMOST, MF_BYCOMMAND)
        and MF_CHECKED > 0;
    if bChecked then
    begin
      CheckMenuItem(pwhi.SubMenu, UM_TOPMOST, MF_BYCOMMAND or MF_UNCHECKED);
      SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE+SWP_NOSIZE)
    end
    else begin
      CheckMenuItem(pwhi.SubMenu, UM_TOPMOST, MF_BYCOMMAND or MF_CHECKED);
      SetWindowPos(Handle,HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE+SWP_NOSIZE)
    end;
  end;

  procedure DoPrintScreen(const pwhi  : PWindowHookInfo);
  //截屏
  var
    dc  : HDC;
    rc  : TRect;
    cvs : TCanvas;
    bmp : TBitmap;
  begin
    dc  :=  GetWindowDC(Handle);
    try
      cvs :=  TCanvas.Create;
      try
        cvs.Handle  :=  dc;
        GetWindowRect(Handle, rc);
        rc.Right  :=  rc.Right - rc.Left;
        rc.Bottom :=  rc.Bottom - rc.Top;
        rc.Left   :=  0;
        rc.Top    :=  0;
        bmp :=  TBitmap.Create;
        try
          bmp.Width   :=  rc.Right;
          bmp.Height  :=  rc.Bottom;
          bmp.Canvas.CopyRect(rc, cvs, rc);
          Clipboard.Assign(bmp);
        finally
          bmp.Free;
        end;
        cvs.Handle  :=  0;
      finally
        cvs.Free;
      end;
    finally
      ReleaseDC(Handle, dc);
    end;
  end;

  procedure DoTransparent(const pwhi  : PWindowHookInfo);
  //设置是否透明
  var
    bChecked  : Boolean;
  begin
    bChecked  :=  GetMenuState(pwhi.SubMenu, UM_TRANSPARENT, MF_BYCOMMAND)
        and MF_CHECKED > 0;
    if bChecked then
    begin
      CheckMenuItem(pwhi.SubMenu, UM_TRANSPARENT, MF_BYCOMMAND or MF_UNCHECKED);
      SetWindowLong(Handle, GWL_EXSTYLE,
          GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_LAYERED);
    end
    else begin
      CheckMenuItem(pwhi.SubMenu, UM_TRANSPARENT, MF_BYCOMMAND or MF_CHECKED);
      SetWindowLong(Handle, GWL_EXSTYLE,
          GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED);
      SetLayeredWindowAttributes(Handle, 0, $80, LWA_ALPHA);
    end;
  end;

  procedure DoSize(const pwhi  : PWindowHookInfo);
  var
    Style : Longint;
  begin
    Style :=  GetWindowLong(Handle, GWL_STYLE);
    SetWindowLong(Handle, GWL_STYLE, Style or WS_SIZEBOX or WS_TILEDWINDOW);
  end;

var
  pwhi  : PWindowHookInfo;
//  r : Integer;
//  ps  : array[0..MAXBYTE] of char;
begin
  pwhi  :=  GetHookInfo(Handle);
  if Assigned(pwhi) then
  begin
    case Msg of
      WM_SYSCOMMAND :
        begin
          case wParam of
            UM_TOPMOST      : UpdateTopMost(pwhi);
            UM_PRINTSCREEN  : DoPrintScreen(pwhi);
            UM_TRANSPARENT  : DoTransparent(pwhi);
            UM_SIZE         : DoSize(pwhi);
            UM_ABOUT        : ShowAbout(pwhi);
          end;
          CallWindowProc(pwhi.OldProc, Handle, Msg, wParam, lParam);
        end;
      {WM_CLOSE  :
        begin
        end; //}

      else begin
        {if WEHData.hGetTextMessage = Msg then
        begin
          r :=  DefWindowProc(Handle, WM_GetText, MAXBYTE, Integer(@ps));
          //CallWindowProc(pwhi.OldProc, Handle, WM_GetText, MAXBYTE, Integer(@ps));
          //SendMessage(Handle, WM_GetText, MAXBYTE, Integer(@ps));
          SetWindowText(FindWindow(nil, '无标题 - 记事本'), PChar(StrPas(ps) + IntToStr(r)));
        end
        else  //}
          CallWindowProc(pwhi.OldProc, Handle, Msg, wParam, lParam);
      end;
    end;  //case

  end;
end;                                                                                        

procedure HookProc(nCode, wParam, lParam: LongWORD);stdcall;
//HOOK回调过程

  procedure InsertMenus(const AWhi  : PWindowHookInfo);
  //插入菜单
  var
    SysMenu : HMenu;
    i       : integer;
    s       : array[0..MAXBYTE] of char;
  begin
    SysMenu :=  GetSystemMenu(AWhi.Handle, False);
    i       :=  GetMenuItemCount(SysMenu)-1;
    AWhi.SubMenu  :=  CreateMenu;
    InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION, UM_ABOUT, PChar(SAbout));
    InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION + MF_SEPARATOR, 0, nil);
    //InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION or MF_UNCHECKED, UM_SIZE, PChar(SSize));
    InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION or MF_UNCHECKED, UM_TRANSPARENT, PChar(STransparent));
    InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION or MF_UNCHECKED, UM_PRINTSCREEN, PChar(SPrintScreen));
    InsertMenu(AWhi.SubMenu, 0, MF_BYPOSITION or MF_UNCHECKED, UM_TOPMOST, PChar(STopMost));

    InsertMenu(SysMenu, i, MF_BYPOSITION + MF_SEPARATOR, 0, nil);
    InsertMenu(SysMenu, i, MF_BYPOSITION or MF_POPUP, AWhi.SubMenu, PChar(SExpand));
    GetMenuString(SysMenu, i - 1, s, MAXBYTE, MF_BYPOSITION);
    AWhi.Separator  :=  s[0] <> #0;
    if AWhi.Separator then
      InsertMenu(SysMenu, i, MF_BYPOSITION + MF_SEPARATOR, 0, nil);
  end;

  procedure DeleteMenus(const AWhi  : PWindowHookInfo);
  //删除菜单
  var
    SysMenu : HMenu;
    i : Integer;
  begin
    SysMenu :=  GetSystemMenu(AWhi.Handle, False);
    i := GetMenuItemCount(SysMenu) - 3;
    DeleteMenu(SysMenu, i, MF_BYPOSITION);
    DeleteMenu(SysMenu, i, MF_BYPOSITION);
    if AWhi.Separator then
      DeleteMenu(SysMenu, i - 1, MF_BYPOSITION);
  end;

  procedure DoHook(AHandle  : HWND);
  //挂钩
  var
    whi : PWindowHookInfo;
  begin
    whi :=  GetHookInfo(AHandle);
    if Assigned(whi) then Exit;
    whi :=  GetEmptyHookInfo;
    if not Assigned(whi) then Exit;

    whi.Handle   :=  AHandle;
    InsertMenus(whi);
    whi.OldProc  :=
      Pointer(GetWindowLong(AHandle, GWL_WNDPROC));
    SetWindowLong(AHandle, GWL_WNDPROC, Longint(@WindowProc));
  end;

  procedure DoUnHook(AHandle  : HWND);
  //脱钩
  var
    whi : PWindowHookInfo;
  begin
    whi :=  GetHookInfo(AHandle);
    if Assigned(whi) then
    begin
      DeleteMenus(whi);
      SetWindowLong(AHandle, GWL_WNDPROC, Longint(whi.OldProc));
      whi.Handle   :=  0;
    end;
  end;

type
  PWMSysCommand = ^TWMSysCommand;
begin
  if PCWPStruct(lParam).Message = WEHData.hHookMessage then
    DoHook(PCWPStruct(lParam).hwnd)
  else if PCWPStruct(lParam).Message = WEHData.hUnHookMessage then
    DoUnHook(PCWPStruct(lParam).hwnd)
  else
    CallNextHookEx(0, nCode, wParam, lParam);
  {
  if PCWPStruct(lParam).Message = WM_SYSCOMMAND then
  begin
    case PWMSysCommand(lParam).CmdType of
      UM_About  : MessageBox(PCWPStruct(lParam).hwnd, '','',0);
      else begin
        MessageBox(PCWPStruct(lParam).hwnd,
            PChar(IntToStr(PCWPStruct(lParam).lParam)),
            PChar(IntToStr(PCWPStruct(lParam).wParam)),0);
        CallNextHookEx(0, nCode, wParam, lParam);
      end;
    end;
  end
  else
    CallNextHookEx(0, nCode, wParam, lParam);
//}
end;

function HookWindowMenu(
    const AOwner  : HWND;
    const AHandle : HWND
    ):Boolean;stdcall;
//导出函数/挂钩
var
  ThreadID  : Longword;
  ProID     : Integer;
begin
  {Result  :=  False;
  if IsWindow(AHandle)
      //and (GetParent(AHandle) = 0)
      and (GetSystemMenu(AHandle, False) > 0)
      and (AOwner <> AHandle)
      and not Assigned(GetHookInfo(AHandle)) then
  begin //}
    ThreadID  :=  GetWindowThreadProcessId(AHandle, @ProID);
    Result    :=  SetWindowsHookEx(
        WH_CALLWNDPROC, //WH_GETMESSAGE,WH_CALLWNDPROC,WH_CALLWNDPROCRET
        @HookProc,
        Hinstance,
        ThreadID
        ) > 0;
    if Result then
    begin
      WEHData.hWindowHandle :=  AOwner;
      SendMessage(AHandle, WEHData.hHookMessage, 0, 0);
    end;
  //end;
end;

function UnHookAllWindowMenu:Boolean;stdcall;
//导出函数/脱钩所有
var
  i : Integer;
begin
  Result  :=  False;        
  for i := Low(WEHData.Hooks) to High(WEHData.Hooks) do
    if WEHData.Hooks[i].Handle > 0 then
      SendMessage(WEHData.Hooks[i].Handle, WEHData.hUnHookMessage, 0, 0);
end;

end.
