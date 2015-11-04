//==============================================================================
// Program  : WindowView
// Author   : ysai
// Date     : 2003-11-28
//==============================================================================

//{$DEFINE _XPDESIGN}

program WindowView;

uses
  Forms,
  Windows,
  Messages,
  MultInst in 'MultInst.pas',
  WindowViewUnit in 'WindowViewUnit.pas',
  BaseFrm in 'BaseFrm.pas' {FrmBase},
  WindowViewFrm in 'WindowViewFrm.pas' {FrmWindowView},
  uFindFile in 'uFindFile.pas',
  XPdesign {$ENDIF};

{$R *.res}

var
  frmTemp : TForm;
begin
  Application.Initialize;
  Application.HintPause     :=  500;
  Application.HintHidePause :=  10000;
  if Application.ShowMainForm then
  begin
    Application.CreateForm(TFrmWindowView, FrmWindowView);
  end
  else
    Application.CreateForm(TForm, frmTemp);
  Application.Run;
end.
