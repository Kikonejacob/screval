unit EP_errdlg;
{----------------Expression Error Dialogs---------------------
Boite de dialoque de rapport des erreurs de l'évaluateur
d'expresssion
->Date:29.07.2008
--------------------------------------------------------------}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls,Eval,gutils;

type
  TErrForm = class(TForm)
    Button1: TButton;
    RText: TRichEdit;
    Descript_text: TMemo;
    Bevel1: TBevel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;
//function  ShowEpError(EpInfo:Pepinfo;Eparr:Strarr;Errmsg:string):integer;
function loadErrInfo(name:string):string;
function ShowEpErrorDlg(epstr:pchar;epstrCount:integer;errpos:integer;errmsg:pchar):integer;


var
  ErrForm: TErrForm;
  ErrList:TStringList;

implementation

{$R *.dfm}
{Fonction qui permet de charger une erreur contenu dans le fichier d'erreur
->Date:29.07.2008}
function loadErrInfo(name:string):string;
var
  i:integer;
begin
try
  if ErrList=nil then
  begin
  ErrList:=TStringList.Create;
  ErrList.LoadFromFile(Application.ExeName);
  end;
  for i:=0 to (ErrList.Count-1) do begin
  if pos(name,ErrList[i])<>0 then
  result:=ErrList[i];
  end;
except
  result:='Error when loading error file description' ;
end;


end;





{---------------------------------------
affiche une boite de dialogue  pour montrer l'erreur dans
l'expression à l'utilisateur
->Date:?,revisé:29.07.2008
-----------------------------------------}
function ShowEpErrorDlg(epstr:pchar;epstrCount:integer;errpos:integer;errmsg:pchar):integer;
var
   slength:integer;
begin

    ErrForm.RText.SelStart:=0;
    ErrForm.Descript_text.Clear;
    ErrForm.RText.Lines.Clear;
    ErrForm.Descript_text.Lines.Add(Format('Erreur d''évaluation à partir de la Colonne %d',[ErrPos+1]));
    ErrForm.Descript_text.Lines.Add('Cause:');
    ErrForm.Descript_text.Lines.Add(Errmsg);
    ErrForm.RText.text:=epstr;
    ErrForm.RText.SelStart:=errpos;
    slength:=pos(copy(epstr,errpos+1,length(epstr)),' ');
    if slength=0 then slength:=length(epstr)-errpos;
    ErrForm.RText.SelLength:=slength;
    ErrForm.RText.SelAttributes.Color:=12000;
    ErrForm.ShowModal;
end;




(*
 
function  ShowEpError(EpInfo:PEpInfo;Eparr:Strarr;Errmsg:string):integer;
var
    i,gpos:integer;
begin
    try
    ErrForm.RText.SelStart:=0;gpos:=0;
    ErrForm.Descript_text.Clear;
    ErrForm.RText.Lines.Clear;
    ErrForm.Descript_text.Lines.Add(Format('Erreur d''évaluation à partir de la Colonne %d',[EpInfo.ErrPos+1]));
    ErrForm.Descript_text.Lines.Add('Cause:');
    ErrForm.Descript_text.Lines.Add(Errmsg);


    For i:=0 to high(Eparr) do begin
     if i=EpInfo.ErrPos then begin
       ErrForm.RText.SelAttributes.Color:=12000;
       ErrForm.RText.SelText:=Eparr[i]; end
     else begin
       ErrForm.RText.SelAttributes.Color:=0;
       ErrForm.RText.SelText:=Eparr[i]
     end;
      gpos:=gpos+Length(Eparr[i]);
    end;
 ErrForm.ShowModal;
 except
 MessageBox(null,'Important pour Jacob','Erreur interne dans EPEVAL',MB_OK+MB_ICONWARNING);
end;
end;
*)
end.
