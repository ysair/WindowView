//==============================================================================
// Program  : WindowView
// Author   : ysai
// Date     : 2003-11-28
//==============================================================================

//{$DEFINE _XPDESIGN}

program WindowView;

uses
  //FastMM4,
  Forms,
  Windows,
  Messages,
  {$IFDEF _XPDESIGN}XPdesign, {$ENDIF}
  MultInst in 'MultInst.pas',
  WindowViewUnit in 'WindowViewUnit.pas',
  BaseFrm in 'BaseFrm.pas' {FrmBase},
  WindowViewFrm in 'WindowViewFrm.pas' {FrmWindowView};

{$R *.res}

var
  frmTemp : TForm;
begin
  Application.Initialize;
  Application.HintPause     :=  500;
  Application.HintHidePause :=  10000;
  //Application.MainFormOnTaskBar :=  True;
  if Application.ShowMainForm then
  begin
    Application.CreateForm(TFrmWindowView, FrmWindowView);
  end
  else
    Application.CreateForm(TForm, frmTemp);
  Application.Run;
end.
