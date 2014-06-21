unit DLG_SCR_ERROR;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,script,eval, ComCtrls, ExtCtrls;


//function  ShowScrError(EpInfo:PEpInfo;scr:pscrInfo;Errmsg:string;texte:string):integer;
function  ShowScrErrDlg(line:integer;msg,scrfile,source:pchar;scrcount,flag:integer):integer;

type
  TE_form = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Descript_text: TMemo;
    Label1: TLabel;
    Panel2: TPanel;
    detail: TRichEdit;
    StatusBar1: TStatusBar;
    procedure Button3Click(Sender: TObject);
    procedure detailMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure detailKeyPress(Sender: TObject; var Key: Char);
    procedure detailChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Panel1Resize(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

    err_pos:integer;
    procedure UpdateCursorPos;
    
  end;

var
  E_form: TE_form;
  lastheight:integer;
resourcestring
  S_PLUS_DETAIL='Détail >>';
  S_MIN_DETAIL='<< Détail';
  E_DESCRIPTION='Erreur d''évaluation à la ligne %d';
  E_ParseDESCRIPTION='Parsing Error at line %d';  

implementation

{$R *.dfm}

{---------------------------------------
affiche une boite de dialogue  pour montrer l'erreur dans
l'expression à l'utilisateur
->Date:?,revisé:29.07.2008 , 26.04.2011
-----------------------------------------}
function ShowScrErrDlg(line:integer;msg,scrfile,source:pchar;scrcount,flag:integer):integer;
begin
    E_form.detail.Lines.Clear;
    E_form.detail.Lines.Append(source);
    //showmessage(source);
    e_form.detail.SelStart:=SendMessage(E_form.detail.Handle, EM_LINEINDEX, line-1, 0);
    e_form.detail.SelLength:=SendMessage(E_form.detail.Handle, EM_LINELENGTH, e_form.detail.SelStart, 0);
    //showmessage(inttostr(e_form.detail.SelLength));
    e_form.detail.SelAttributes.Color:=rgb(255,10,10);
    e_form.detail.SelAttributes.Style:=[fsbold];

    if (flag=1) then
    E_form.label1.caption:=(Format(E_PARSEDESCRIPTION,[line]))
    else
    E_form.label1.caption:=(Format(E_DESCRIPTION,[line]));

    E_form.Descript_text.Clear;
    E_form.Descript_text.Lines.Add('>'+E_form.label1.caption+ ' , '+format('source: "%s"',[scrfile]));
    E_Form.Descript_text.Lines.Add(format(':.(line %d) %s',[ line,msg]));
    E_Form.ShowModal;

end;
(*
function  ShowScrError(EpInfo:PEpInfo;scr:PscrInfo;Errmsg:string;text:string):integer;
var
    i,a,gpos:integer; html:TstringList;str,str2:string;
    msg:string;
    line,col,scrfilepos:integer;
    source,scrFile:string;
    errScr:PscrInfo;
    nsId:integer;
begin

    html:=TstringList.Create;
    //E_Form.label1.caption:='Cause:';
    if (scr.error_namespace=scr.name)  then
    begin
      line:=scr.error_line;
      msg:=scr.error_msg ;
      source:=scr.texte;
      scrfile:=scr.scrFileName;
      //showmessage('kjkj single');
      //showmessage(source);
    end
    else
    begin
      //showmessage('kjkjkjkjkjkjk  '+scr.error_namespace);
      errScr:=PScrInfo(namespacelist[indexfromNamespace(scr.error_namespace)]);
      scrfilepos:=errScr.scrFilePos;
      //showmessage(inttostr(errscr.error_line));
      //showmessage(errscr.Namespace+ ' namespace  '+errscr.parentNamespace);
      //showmessage('file name: '+errscr.scrFileName);
      msg:=errScr.error_msg;
      //if errscr.scrFileName='#parent#' then   showmessage('file name: '+errscr.scrFileName);
      //showmessage(inttostr(errscr.ParentIndex));
      line:= errScr.error_line; {ligne  uniquement à l'échelle du namespace local}
      while  (errscr.scrFileName='#parent#') do
      begin
        nsid:=indexFromNameSpace(errScr.parent);
        if (nsid=-1)  then break;
        errScr:=PscrInfo(namespacelist[nsid]);

      end;
      source:=errScr.texte;
      line:=line+xcount_delimiter(#13#10,copy(source,0,scrfilepos));
      //showmessage(copy(source,0,scrfilepos));

      scrfile:=errScr.scrFileName;

    end;
    E_form.label1.caption:=(Format(E_DESCRIPTION,[line]));
    if Epinfo=nil then
    E_form.label1.caption:=(Format(E_PARSEDESCRIPTION,[line]));
    E_form.Descript_text.Clear;
    E_form.Descript_text.Lines.Add('>'+E_form.label1.caption+ ' , '+format('source: "%s"',[scrfile]));

    E_Form.Descript_text.Lines.Add(format(':.(line %d) %s',[ line,msg]));

    {
    i:=0;
    html.Text:=scr.texte;

    str:=copy(scr.texte,1,scr.instructions[EpInfo.scr_index].position);
    str:=str+'<strong class="errmsg">';
    str2:=copy(scr.texte,scr.instructions[EpInfo.scr_index].position,pos(#13#10,html.text));
    if str2='' then
    str2:=copy(scr.texte,scr.instructions[EpInfo.scr_index].position,+1);
    html.Text:=str+'</strong>'+str2;
     }

    {if  (pos(#13#10,str) >0) then  a:=pos(#13#10,str)  else    a:=length(str);
    while(a>0)  do
    begin
      html.Text:=html.Text+inttostr(i)+':'+copy(str,1,a);
      inc(i);
      str:=copy(str,a+2,length(str)- a);
      a:=pos(#13#10,str)
    end;
    html.SaveToFile('c:\SCRIPT_SCHEDIT_ERROR.html');
    E_Form.detail.Lines.LoadFromFile('c:\SCRIPT_SCHEDIT_ERROR.html');
     }
    //E_Form.detail.Show;
    E_form.detail.Lines.Text:= source;

    //showmessage(source);

    e_form.detail.SelStart:=SendMessage(E_form.detail.Handle, EM_LINEINDEX, line-1, 0);

    e_form.detail.SelLength:=SendMessage(E_form.detail.Handle, EM_LINELENGTH, e_form.detail.SelStart, 0);
    //showmessage(inttostr(e_form.detail.SelLength));
    e_form.detail.SelAttributes.Color:=rgb(255,10,10);
    e_form.detail.SelAttributes.Style:=[fsbold];
    //e_form.detail.SelLength:=length(scr.instructions[epInfo.scr_index].text);
    //  showmessage('jkjk');
    if epInfo<>nil then
    e_form.err_pos:=scr.instructions[epInfo.scr.index].position;
    E_Form.ShowModal;


end;
*)


procedure TE_form.Button3Click(Sender: TObject);
begin
detail.SelStart:=err_pos;
if panel2.Visible then
detail.SetFocus;
end;
procedure TE_Form.UpdateCursorPos;
var
  CharPos: TPoint;
begin
  CharPos.Y := SendMessage(detail.Handle, EM_LINEFROMCHAR,detail.SelStart ,0   );
  CharPos.X := (detail.SelStart -
    SendMessage(detail.Handle, EM_LINEINDEX, CharPos.Y, 0));
  Inc(CharPos.Y);
  Inc(CharPos.X);
  StatusBar1.Panels[0].Text := Format('line:%d,column:%d', [CharPos.Y, CharPos.X]);
end;
procedure TE_form.detailMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 UpdateCursorPos;
end;

procedure TE_form.detailKeyPress(Sender: TObject; var Key: Char);
begin
 UpdateCursorPos;
end;

procedure TE_form.detailChange(Sender: TObject);
begin
   UpdateCursorPos
end;

procedure TE_form.Button2Click(Sender: TObject);
begin
 if panel2.Visible then
 begin
   panel2.Align:=alnone;
   lastheight:=self.ClientHeight;
   self.ClientHeight:=panel1.Height;
   button2.Caption:=S_PLUS_DETAIL;

   panel2.Visible:=false;
 end
 else
 begin
   self.ClientHeight:=lastheight;
   panel2.Visible:=true;
   panel2.Align:=alclient;
   button2.Caption:=S_MIN_DETAIL;
   detail.SetFocus;
 end;


end;

procedure TE_form.Panel1Resize(Sender: TObject);
begin
descript_text.Width:=self.ClientWidth-20;
button1.Left:=self.ClientWidth-button1.Width-10;
end;

end.
