program bitcashminer;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.ShowMainForm := false;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  MainForm.StartMiningNow;
  Application.Run;
end.
