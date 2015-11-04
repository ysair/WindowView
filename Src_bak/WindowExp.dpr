library WindowExp;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  windows,
  Messages,
  WindowExpHook in 'WindowExpHook.pas',
  WindowExpRes in 'WindowExpRes.pas';

{$R *.res}

exports
  HookWindowMenu,
  UnHookAllWindowMenu;

const
  SMapFileName  : PChar = '{B379FBD2-533B-4BC6-80EC-C335B3221CB8}';

var
  hMapHandle: LongWORD;
  
procedure DLLHandler(Reason: Integer);
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin            //建立文件映射,以实现DLL中的全局变量
        hMapHandle := CreateFileMapping(
            DWORD(-1),
            nil,
            PAGE_READWRITE,
            0,
            SizeOf(WEHData),
            SMapFileName
            );
        if hMapHandle = 0 then
          if GetLastError = ERROR_ALREADY_EXISTS then
          begin
            hMapHandle := OpenFileMapping(
                FILE_MAP_ALL_ACCESS,
                False,
                SMapFileName
                );
          end;

        if hMapHandle > 0 then
        begin
          WEHData := MapViewOfFile(
              hMapHandle,
              FILE_MAP_ALL_ACCESS,
              0,
              0,
              0
              );
          if WEHData = nil then
            CloseHandle(hMapHandle)
          else begin
            WEHData.hHookMessage  := RegisterWindowMessage(SMsg_WEH_Hook);
          end;
        end;
      end;
    DLL_PROCESS_DETACH:
      begin
        if Assigned(WEHData) then
        begin
          //CloseHandle(DllData.Mutex);
          UnmapViewOfFile(WEHData);
          WEHData := nil;
          CloseHandle(hMapHandle);
        end;
      end;
  end;
end;

begin
  DLLProc := @DLLHandler;
  DLLhandler(DLL_PROCESS_ATTACH);
end.
