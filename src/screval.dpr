program screval;
{$DEFINE EPEVAL}
{$DEFINE FullDebugMode}
{%File 'common.inc'}

uses
  FastMM4,forms,
  errCode in 'errCode.pas',
  eval in 'eval.pas',
  eval_extra in 'eval_extra.pas',
  regeval in 'regeval.pas',
  scr_reg_eval in 'scr_reg_eval.pas',
  script in 'script.pas',
  TEST_form1 in 'DLG\TEST_form1.pas' {Form4},
  gutils in '..\gutils.pas',
  main in 'main.pas',
  common in 'common.pas';

{$R *.res}

begin
  Application.Initialize;
  initEval;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
