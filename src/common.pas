unit common;
{$DEFINE ERR_RICHDLG}

interface

uses eval,windows,dialogs,sysutils;

function loadErrInfo(name:string):string;
function ShowScrErrDlg(line:integer;msg,scrfile,source:pchar;scrcount,flag:integer):integer;
function ShowEpErrorDlg(epstr:pchar;epstrCount:integer;errpos:integer;errmsg:pchar):integer;

procedure ShowMessage(Msg:string);
procedure InitErrDialogs;


implementation
uses DLG_SCR_ERROR,ep_errdlg;



procedure ShowMessage(Msg:string);
begin
 //dialogs.ShowMessage(Msg);
 MessageBox(0,Pchar(msg),'EPEval',MB_OK);
end;

function loadErrInfo(name:string):string;
begin
  result:=ep_errdlg.loadErrInfo(name)
end;

function ShowScrErrDlg(line:integer;msg,scrfile,source:pchar;scrcount,flag:integer):integer;
const
  sMsg='Source:"%s" '+#13#10+'Line: %d'+#13#10+'%s ';
var
  str:string;
begin

    {$IFDEF ERR_RICHDLG}
    result:=DLG_SCR_ERROR.ShowScrErrDlg(line,msg,scrfile,source,scrcount,flag);
    {$ELSE}
    if (flag=1) then str:='Parsing Error' else str:='Evaluation Error';
    MessageBox(0,pchar(format(sMsg,[scrfile,line,msg])),pchar(str),MB_OK+MB_ICONERROR);
    {$ENDIF}
end;

function ShowEpErrorDlg(epstr:pchar;epstrCount:integer;errpos:integer;errmsg:pchar):integer;
const
  sMsg='Error:"%s"'+#13#10+#13#10+'%s';
  sTitle='Erreur d''évalutation à la colonne %d  ';
begin
  {$IFDEF ERR_RICHDLG}
  result:=ep_errdlg.ShowEpErrorDlg(epstr,epstrCount,errpos,Errmsg) ;
  {$ELSE}
  MessageBox(0,pchar(format(sMsg,[string(errmsg),string(epstr)])),pchar(format(sTitle,[errpos])),MB_OK+MB_ICONERROR);
  {$ENDIF}
end;


procedure InitErrDialogs;
begin
  ErrForm:=TErrForm.create(nil);
  E_form:=TE_form.create(nil);
end;

procedure FreeErrDialogs;
begin
  FreeAndNil(ErrForm);
  FreeAndNil(E_Form);
end;

initialization
  {initialise les boites de dialogs}
  initErrDialogs;
finalization
  freeErrDialogs;


end.
