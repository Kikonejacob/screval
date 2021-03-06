unit TEST_form1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,script,eval,scr_reg_eval,alloc, eval_extra,StdCtrls,gutils, XPMan ;

type
  TForm4 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Memo2: TMemo;
    Button2: TButton;
    Edit1: TEdit;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    XPManifest1: TXPManifest;
    myScreen: TMemo;
    Button6: TButton;
    Button7: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}
function MyScreenHandler(text:pchar;buffSize:integer;data:pointer):integer;stdcall;
begin
  form4.myScreen.Lines.Add(string(text));
end;

procedure TForm4.Button1Click(Sender: TObject);
var
 scr:PscrInfo;
 sc:Pinstructions;
 i:integer;
begin
 new(scr);
 sc:=scr_decompose(memo1.Text,scr);
 memo2.Text:='';
 //msgbox(inttostr(length(sc)));
 for i:=0 to high(sc) do
 begin
 memo2.Text:=memo2.Text+sc[i].text+'  ['+inttostr(sc[i].position)+']';
 end;
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
memo1.SetFocus; memo1.SelLength:=1;
memo1.SelStart:=strtoint(edit1.text);

end;

procedure TForm4.Button3Click(Sender: TObject);
var
  scr:PscrINFO;
begin
  //showmessage(memo2.Lines.Text);
  scr:=scr_eval(0,memo2.Lines.Text);
  //dispose(scr);
  
end;

procedure TForm4.Button4Click(Sender: TObject);
begin
 reg_scr_op();
end;

procedure TForm4.FormCreate(Sender: TObject);
var
  evalEventHook:PEvalEventHook;
begin
  new(evalEventHook);
  evalEventHook.PID:=0;
  evalEventHook.ScreenHandler:=@MyScreenHandler ;
  evalEventHook.cbsize:=SizeOf(evalEventHook);
  SetEvalHook(evalEventHook);

  reg_scr_op();
end;

procedure TForm4.Button5Click(Sender: TObject);
var
 gar:strarr;
 i:integer;
 PAR:intarr;
 j:integer;
begin
 gar:=GetDecomposeEx(memo1.Text,'";+;-;*;/;";'';',true);
 for i:=0 to high(gar) do
 begin
   memo2.Lines.Add(gar[i]);

 end;

end;
procedure TForm4.Button6Click(Sender: TObject);
begin
 EvalScriptFromFile(0,extractfilepath(application.ExeName)+'\sch list.php','');
end;

procedure Bela (PID:integer;func:pfunc;ruInfo:pointer;result:Prinfo;EPInfo:pointer);
begin
  result.rtype:=vt_char;
  result.CharValue:='trrt';
  //strcopy('I''m ready',result.charvalue);
end;

procedure TForm4.Button7Click(Sender: TObject);
var
  func:Pfunc;
begin
  new(func);
  fillfunc(func);
  func.PID:=ROOT_PID;
  func.name:='bela';
  func.access:=aPublic;
  func.pfunc:=@bela;
  func.rtype:=vt_char;
  func.ftype:=ft_virtual2;
  Setfunc(ROOT_PID,func,func.name,func.groupe);

end;

end.
