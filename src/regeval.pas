unit regeval;
 {------------------ Register Evalutor---------------------
 Cette partie contient les function,opérateurs déclarés dans l'évaluateur
 d'expression
 ->Date:?,19.07.2008
 amélioré le 13.10.2008
  resivsion  25 aout 2009
  revision  avril septembre 2010
  22 avril 2011 correction d'une erreur dans eval_echo qui affectait les namespaces;
  27 avril 2011 amelioriation concatenaion avec operateur +;
  30 avril problèmes dans echo

  08.06.2012 Addsupport basic boolean the following operators:xor,or,and
  10.16.2012 correction for mutiplication and division function
 ----------------------------------------------------------}
interface
uses windows,eval,common,classes,sysutils,eval_extra,{listaff,dbutils,}gutils,forms,math,variants;
function add(EpInfo:PepInfo;Eparr:Strarr;rInfo:PrInfo):integer;
function Reg_Operators:integer;
function Reg_Functions:integer;
function Reg_Const:integer;
function Reg_namespaces:integer;
procedure AddEpFunc(Func:Pfunc);stdcall;
procedure AddEpConst(EpConst:PConstInfo);stdcall
function ep_h(a,b:integer;c,d:Pchar;e:boolean):boolean stdcall;
function ep_d:integer;  stdcall;
procedure ep_e;stdcall;
function Selstr(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function Jk_StrPos(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;

{Stocker et lire des constantes}
function read_bool(name:pchar):boolean; stdcall;
function read_int(name:pchar):integer; stdcall;
function read_char(name:pchar):Pchar; stdcall;
procedure Sto_bool(Name:pchar;value:boolean)stdcall;
procedure Sto_int(Name:pchar;value:integer)stdcall;
procedure Sto_char(Name:pchar;value:Pchar)stdcall;


function ep_msgbox(title,text:pchar;flag:integer):integer; stdcall;
function ep_showmsg(text:pchar):integer;stdcall;
function eval_echo(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function eval_inc_dec(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function eval_preconcat(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function eval_segment(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;


function dconcact(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function eval_affect_fleche(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function Eval_access_right(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;

function eval_array_keyAffect(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
function Eval_type(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
procedure eval_Xcommon_funcs(PID:integer;func:pfunc;ruInfo:pointer;result:Prinfo;EPInfo:pointer);stdcall;


function ep_strlen(str:pchar):integer; stdcall;
function ep_strTrim(str:pchar):pchar; stdcall;
function ep_strchr(x:integer):pchar; stdcall;
function ep_strReplace(str,oldPattern,newPattern:string):pchar;stdcall ;
function ep_mathPi:double stdcall;
function ep_mathCos(val:double):double stdcall;
function ep_mathSin(val:double):double stdcall;
function ep_mathtan(val:double):double stdcall;
function ep_strpos(substr,str:pchar):pchar; stdcall;



//function eval_dbquery(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;

implementation



{------------------Fonction d'addition----------
principe:
dès que c'est un '+' on doit respecter la priorité de (x et/) sur (- et +)
donc on crèe  une cmd en indiquant à la fonction evaloperator qu'il faut
évaluer jusqu'a rencontrer un + ou un - alors dans ce cas la fonction mère
arrête l'évaluation à ce niveau.
mise ajour 28.aout.2010 : ajoute du concatenance de chaines de caractères}
function add(EpInfo:PepInfo;Eparr:Strarr;rInfo:PrInfo):integer;
var dresult:prinfo;s_inf:pepinfo;
begin

  {char concatenation}
  if (rinfo.rtype=vt_char) then
  begin
    dconcact(EpInfo,Eparr,rinfo);
    //showmessage('gfgf');
    exit;
  end;

  {just for incrementation}
    if (EpInfo.x+1<=high(Eparr)) then
    if Eparr[EpInfo.x+1]='+' then
    begin
    Eval_inc_dec(EpInfo,Eparr,rInfo);
    exit;
    end;
  {end for incrementation}
   if EpInfo.x>=high(eparr) then {évite un bug 30.04.2011}
  begin
    signalerror(EpInfo,s_inf.x,E_SYNTAX,'');
    exit;
  end;
  {var concat}
  if eparr[epInfo.x+1]='=' then
  begin
    //inc(EpInfo.x);
    Epinfo.x:=EpInfo.x;
    exit;
  end;
  New(S_inf);
  fillEpInfo(s_inf);
  New(dresult);
  //showmessage('Addition');
  //dresult^:=rinfo^;
  {dresult.IntValue:=0;
  dresult.CharValue:=stralloc(255) ;     }
  FillrInfo(dresult);
  epInfoCopy(s_inf,EpInfo);
  inc(EpInfo.x);
  Epinfo.cmd:=WorkAddition;
  Epinfo.cArg1:='+-';



  if operateint(EpInfo,EParr,dresult)=0 then
  begin
    If EpInfo.ErrId<>E_NONE then
    begin
       freerinfo(dresult);
       freeEpInfo(s_inf);
       exit;
    end;
    if dresult.rtype=vt_char then {au ou on concat un un integer avec un string pour donner un string}
    begin
      epInfoCopy(epInfo,s_inf);//EpInfo^:=s_inf^;
      dconcact(EpInfo,Eparr,rinfo);
      exit;
    end
    else
    if s_inf.x=0 then
    begin
    rinfo.floatvalue:=dresult.floatvalue;
    rinfo.IntValue:=round(rinfo.floatvalue);
    rInfo.rtype:=vt_integer;
    end
    else
    begin
    if CheckCompatible(rinfo,dresult,vt_numeric)=false then
             SignalError(EpInfo,s_Inf.x,E_OpError,'');
    try
      rinfo.floatvalue:=rinfo.floatValue+dresult.floatvalue;
      rinfo.IntValue:=round(rinfo.floatvalue);
      if round(rInfo.floatvalue) <>rInfo.floatvalue then
      begin
        rInfo.rtype:=vt_float;
       //showmessage('value float==int');
      end;
    except
     SignalError(EpInfo,s_Inf.x,E_OpError,'Unable to perform addition')
    end;
    
    end;
    //StrDispose(dresult.CharValue);
    freerInfo(dresult);
  end;
  
  EpInfo.cmd:=s_inf.cmd;
  EpInfo.traited:=true;{Verifie que traited=true}
  EpInfo.x:=Epinfo.x-1;
  freeEpInfo(s_inf);
end;

{------------------Fonction soustraction----------
->Date:19.07.2008
--------------------------------------------------}
function substract(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin
  {affect fleche}
  if (Eparr[EpInfo.x]='-') and ((EpInfo.x+1)<=high(Eparr)) then
  if (Eparr[EpInfo.x+1]='>') then
  begin
    eval_affect_fleche(Epinfo,Eparr,rinfo);
    exit;
  end;
   if EpInfo.x>high(eparr) then {évite un bug 30.04.2011}
  begin
    signalerror(EpInfo,s_inf.x,E_SYNTAX,'');
    exit;
  end;
  {var concat}
  if eparr[epInfo.x+1]='=' then
  begin
    //inc(EpInfo.x);
    exit;
  end;

  {just for incrementation}
    if (EpInfo.x+1<=high(Eparr)) then
    if Eparr[EpInfo.x+1]='-' then
    begin
   // showmessage('kjk');
    Eval_inc_dec(EpInfo,Eparr,rInfo);
    exit;
    end;
  {end for incrementation}
  //Showmessage('Substract');
  //rInfoCopy(dresult,rinfo);
  //dresult.IntValue:=0;
  new(dresult); new(S_inf);
  FillEpInfo(s_inf);
  Fillrinfo(dresult);
  //s_inf^:=EpInfo^;
  EpInfoCopy(s_inf,EpInfo);
  inc(Epinfo.x);
  Epinfo.cmd:=Workaddition;
  Epinfo.cArg1:='+-';

  if Operateint(Epinfo,Eparr,dresult)=0 then
  begin
   If EpInfo.ErrId<>E_NONE then
    begin
       freerinfo(dresult);
       freeEpInfo(s_inf);
       exit;
    end;
    if (s_inf.x=0) then{Si par exemple c'est -5666+255}
    begin
      rinfo.floatvalue:=-dresult.floatvalue;
      rinfo.IntValue:=round(rinfo.floatvalue);
      //Showmessage('moins'+floattostr(rInfo.floatvalue));
      rInfo.rtype:=vt_integer;
    end
    else
    begin

      if (rinfo.rtype=vt_null) or (rinfo.rtype=vt_null)or CheckCompatible(rinfo,dresult,vt_numeric)=false then
      begin
             SignalError(EpInfo,s_Inf.x,E_Incompatible,'');
      end;
      begin
         try
            rinfo.floatvalue:=rinfo.floatvalue-dresult.floatvalue;
            rinfo.IntValue:=round(rinfo.floatvalue);
            if rinfo.rtype<>vt_integer then rInfo.rtype:=vt_float;
            if round(rInfo.floatvalue) <>rInfo.floatvalue then
            begin
            rInfo.rtype:=vt_float;
            //showmessage('value float==int');
            end;
         except
         SignalError(EpInfo,s_Inf.x,E_OpError,'Impossible to perform subtraction');
         end;
      end;
    end;
  end else
    rinfo.ErrId:=dresult.ErrId;

  Epinfo.cmd:=worknone;
  EpInfo.traited:=true;{Verifie que traited=true}
  EpInfo.x:=Epinfo.x-1;
  //Showmessage('moins'+floattostr(rInfo.floatvalue));
  freerinfo(dresult);
  freeEpInfo(s_inf);
end;

{------------------Fonction diviser----------
fonction opératrice qui permet de diviser
->Date:19.07.2008
----------------------------------------------}

function divise(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin
  New(dresult);New(s_inf);
 // s_inf^:=Epinfo^;
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);
  Epinfo.cmd:=worknone;
  inc(Epinfo.x);
  {16/10/2012}
  //Epinfo.y:=Epinfo.x;
  //Epinfo.cmd:=worknone;
  EpInfo.cmd:=workUntilType;
  EpInfo.cArg2:=vt_numeric;
  {fin 16/10/2012}
   //dresult.IntValue:=0;
  FillrInfo(dresult);
  //showmessage('diviser');
  if EpInfo.x>high(eparr) then {évite un bug 30.04.2011}
  begin
    signalerror(EpInfo,s_inf.x,E_SYNTAX,'');
    exit;
  end;
  if (operateint(Epinfo,Eparr,dresult)=0) then
  begin
    If EpInfo.ErrId<>E_NONE then
    begin
       freerinfo(dresult);
       freeEpInfo(s_inf);
       exit;
    end;
    try
      if CheckCompatible(rinfo,dresult,vt_numeric) then
      begin
      if dresult.floatvalue<>0 then
      rinfo.floatvalue:=rinfo.floatvalue / dresult.floatvalue
      else
      signalError(EpInfo,EpInfo.x-1,E_DivError,'')
      end  else
      SignalError(EpInfo,s_Inf.x,E_OpError,'');
    except
       SignalError(EpInfo,s_Inf.x,E_OpError,'Unable to perform the division');
    end;
  end
  else
    rinfo.ErrId:=dresult.ErrId;
  rinfo.IntValue:=round(rinfo.floatvalue);
  if round(rInfo.floatvalue) <>rInfo.floatvalue then
  begin
  rInfo.rtype:=vt_float;
  //showmessage('value float==int');
  end;
  Epinfo.y:=s_inf.y;
  EpInfo.x:=Epinfo.x-1;
  Epinfo.cmd:=s_inf.cmd;
  EpInfo.traited:=true;
  //showmessage('kjjjk')
  freerinfo(dresult);
  freeEpInfo(s_inf);
end;
{------------------Fonction Multiplier----------
Fonction opératrice qui permet de multiplier
->Date:19.07.2008
------------------------------------------------}
function Multiply(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin
  New(dresult);New(s_inf);
  //s_inf^:=Epinfo^;
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);
  Inc(Epinfo.x);
  {16/10/2012}
  //Epinfo.y:=Epinfo.x;
  //Epinfo.cmd:=worknone;
  EpInfo.cmd:=workUntilType;
  EpInfo.cArg2:=vt_numeric;
  {fin 16/10/2012}
  //dresult^:=rinfo^;
  //rinfoCopy(dresult,rinfo);
  //dresult.IntValue:=0;
  FillrInfo(dresult);
  //showmessage('Multiplied');
  if EpInfo.x>high(eparr) then {évite un bug 30.04.2011}
  begin
    signalerror(EpInfo,s_inf.x,E_SYNTAX,'');
    exit;
  end;
  if operateint(Epinfo,Eparr,dresult)=0 then
  begin
   If EpInfo.ErrId<>E_NONE then
    begin
       freerinfo(dresult);
       freeEpInfo(s_inf);
       exit;
    end;
    if CheckCompatible(rinfo,dresult,vt_numeric)=false then
             SignalError(EpInfo,s_Inf.x,E_OpError,'');
    try
      rinfo.floatvalue:=rinfo.floatvalue*dresult.floatvalue;
      rinfo.IntValue:=round(rinfo.floatvalue);
      if (rinfo.rtype=vt_integer) and (dresult.rtype=vt_float) then
      begin
        rinfo.rtype:=dresult.rtype ;
      end;
    except
      SignalError(EpInfo,s_Inf.x,E_OpError,'Unable to perform de Multiplicationn');
    end;

  end else
    rinfo.ErrId:=dresult.ErrId;
  EpInfo.x:=Epinfo.x-1; {puisque il yaura un inc avant qu x>y}
  Epinfo.y:=s_inf.y;
  Epinfo.cmd:=s_inf.cmd;  {a voir si ya erreur dans libscreval}
  EpInfo.traited:=true;
  freerinfo(dresult);
  freeEpInfo(s_inf);
end;
{------------------Fonction paranthèse----------
fonction opératrice qui permet d'évaluer les expressions entre parenthèses
->Date:19.07.2008
---------------------------------------------}
function Paranthese(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  //dresult:prinfo;
  s_inf:Pepinfo;
  gparEndPos:integer;
begin
  //New(dresult);
  //dresult.CharValue:=stralloc(255);
  //FillrInfo(dresult);
  New(s_inf);
  fillEpInfo(s_inf);
  gparEndPos:=GetParaEnd(Eparr,Epinfo.x);
  //ShowMessage('Parenthèse');
  //showmessage( inttostr(Integer(EpInfo.prev_traited))+'dfdf');


  If gparEndPos>(-1) then begin
    if (Epinfo.prev_traited<>pt_operator)  and (Epinfo.prev_traited<>pt_none)then  {verifie que la colonne précédante est un opérateur}
    begin
    SignalError(EpInfo,EpInfo.x,E_PERSONAL,' la parenthèse doit être précédé par un operateur');
    EpInfo.x:=EpInfo.x+1;
     exit;
    end;
    //s_inf^:=Epinfo^;
    EpInfoCopy(s_inf,EpInfo);
    EPinfo.cmd:=worknone;
    Inc(EpInfo.x);
    EpInfo.y:=(gparEndpos-1);

    //rinfoCopy(dresult,rinfo); //dresult^:=rInfo^;
    Operateint(Epinfo,Eparr,rinfo)
  end else
   SignalError(EpInfo,EpInfo.x,E_NoParaEnd,''); {rinfo.ErrId:=1;{'noparamend'}



  EpInfo.y:=S_inf.y;
  EpInfo.x:=EpInfo.x; {dès la fin inc(epinfo.x)}
  EpInfo.cmd:=s_inf.cmd;
  freeEpInfo(s_inf);
end;

{------------------Fonction concat---------
fonction operatrice qui permet de concacter du texte
->Date:19.07.2008
------------------------------------------------------}
function dconcact(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;
  s_inf:Pepinfo;
  s:Pchar;
  op:Poperator;
  size:integer;

begin
 {pour voir si c'est pas "&=" remplacé par "+=" }
 if (Eparr[EpInfo.x]='+') or (Eparr[EpInfo.x]='.') then
 begin
   new(op);
   if (getoperator(Eparr[EpInfo.x+1],op)=0)  and (pos(Eparr[EpInfo.x+1],'";''')=0) then
   begin
    showmessage(Eparr[EpInfo.x+1]+'___'+op.name);
   signalError(EpInfo,EpInfo.x,E_Syntax,'concatenation Operator use');
   exit;
   end;
   dispose(op);
 end;

 {essaie de convertir la valeur antérieur de rinfo en string}
 if (rinfo.rtype=vt_integer) or (rinfo.rtype=vt_bool) or (rinfo.rtype=vt_float) then
 begin

  //showmessage(cnv_rinfotostr(rinfo));
  strcopy( rinfo.CharValue,Pchar( cnv_rinfotostr(rinfo)));
  rinfo.rtype:=vt_char;{on modifie automatiquement le type a revoir pour modifier }
 end;

 if (EpInfo.x+1<=high(Eparr))  then
 if Eparr[EpInfo.x+1]='=' then
 begin
  eval_preconcat(EpInfo,Eparr,rinfo);
  exit;
 end;

 New(s_inf);
 fillEpInfo(s_inf);
 saveepinfo(EpInfo,s_inf);
 Inc(s_inf.x);
 //s_inf.y:=s_inf.x;    {A REVOIR}
 New(dresult);
 //dresult.charvalue:=stralloc(255);
 fillrinfo(dresult);
 //showmessage(eparr[s_inf.x]);
 OperateInt(s_inf,Eparr,dresult);

 if s_inf.ErrId<>E_NONE then
 begin
   copyEpError(s_inf,EpInfo);
    freeEpInfo(s_inf);
    freerInfo(dresult);

   //showmessage('errrorrrr');
   exit;
 end;
 if (dresult.rtype=vt_integer) or (dresult.rtype=vt_float) or (dresult.rtype=vt_numeric) or (dresult.rtype=vt_bool) then
 begin
  // dresult.CharValue:=pchar(inttostr(dresult.IntValue));
   strcopy(dresult.CharValue,pchar(cnv_rinfotostr(dresult)));
 end
 else
 if CheckCompatible(rinfo,dresult,vt_char)=false  then
 begin
{  CheckCompatible(rinfo,dresult,vt_char);
  showmessage(rinfo.CharValue);
  showmessage(dresult.CharValue);   }
  SignalError(EpInfo,EpInfo.x,E_Incompatible,'');
 end;

 size:=strlen(dresult.CharValue)+1;{pour le charactère de fin}
 size:=size+strlen(rinfo.CharValue)+1;{pour le charactère de fin}
 s:=stralloc(size);
 ;//getmem(s,strlen(rinfo.CharValue)+strlen(dresult.CharValue));
 strcopy(s,rinfo.CharValue);
 //showmessage(rinfo.charvalue);
 strcat(s,dresult.CharValue);
 strDispose(rinfo.CharValue);
 rinfo.CharValue:=stralloc(size);
 //Getmem(rinfo.CharValue,strlen(s));
 strcopy(rinfo.CharValue,s);
 EpInfo.x:=s_inf.x-1;
 rinfo.CharBuffSize:=strBufSize(rinfo.CharValue);
 //EpInfo.x:=EpInfo.x+1;
//showmessage(inttostr(epinfo.x));
// showmessage(Eparr[EpInfo.x-1]);
 strDispose(s);
 freeEpInfo(s_inf);
 //strDispose(dresult.CharValue);
 freerInfo(dresult);

 end;
{------------------Fonction Selstr---------
fonction opératrice qui permet d'avoir du texte
->Date:19.07.2008
---------------------------------------------}
{a revoir}
function Selstr(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  g:string;
  i:integer;
  size:integer;
begin
  if epinfo.x>high(eparr) then showmessage('kjk');
  if (Eparr[EpInfo.x]='"') or (Eparr[epInfo.x]='''') then
  if (high(eparr)-EpInfo.x)<1 then
  begin
    SignalError(EpInfo,EPInfo.x,E_NoCharEnd,'');
    exit;
  end;
  if (EParr[Epinfo.x]<>Eparr[EpInfo.x+1])then
  g:=Eparr[Epinfo.x+1];
  (*{Replace les guillemet(\") et les apostrophe (\'}
  g:=StringReplace(g,'%a','"',[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,'%b''','''',[rfReplaceAll,rfIgnoreCase]);
   *)
  g:=StringReplace(g,#10,'',[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,#13,'',[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,'\\','\',[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,'\n',#13#10,[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,'\''','''',[rfReplaceAll	,rfIgnoreCase]);
  g:=StringReplace(g,'\"','"',[rfReplaceAll	,rfIgnoreCase]);
  g:=stringReplace(g,'\33',' ',[rfReplaceAll	,rfIgnoreCase]);

 { if (EpInfo.x+2)>high(Eparr) then
  SignalError(EpInfo,EPInfo.x,E_NoCharEnd,'')
  else }
  if (EpInfo.x+2)>high(Eparr) then
  begin
    if (pos((Eparr[EpInfo.x+1]),''',"')>0) then
    begin
       strcopy(rinfo.CharValue,'');
       inc(Epinfo.x){rien a ajouter}
    end
    else
       SignalError(EpInfo,EPInfo.x,E_NoCharEnd,'');
    exit;
  end
  else
  if (Eparr[EpInfo.x+2]<>Eparr[EpInfo.x]) and (Eparr[EpInfo.x+1]<>Eparr[EpInfo.x]) then
  begin
    SignalError(EpInfo,EPInfo.x,E_NoCharEnd,'');
  end;

 { for i:=0 to high(Eparr) do
  begin
  end;}
  if rinfo=nil then showmessage('jkjk:rinfo is  nil');
//  showmessage(inttostr(length(g)));
 //if  StrBufSize (rInfo.CharValue)< StrBufSize(pchar(g)) then
  //rinfo.CharValue:=stralloc(sizeOf(g)+2);
  size:=strlen(pchar(g))+1;{pour le charactère de fin}
  strdispose(rinfo.CharValue);
  rinfo.CharValue:=stralloc(size);
  strcopy(rinfo.CharValue,Pchar(g));
  rinfo.CharBuffSize:=strbufSize(rinfo.CharValue);
  //rinfo.CharValue:=strNew(pchar(g));
  if Eparr[EpInfo.x+1]=Eparr[EpInfo.x]  then
    Epinfo.x:=Epinfo.x+1
  else
    Epinfo.x:=Epinfo.x+2;
  rinfo.rtype:=vt_char;
  //showmessage(rinfo.CharValue);
  SetLength(g,0);

end;


{------------------Fonction de l'opérateur = ----------
->Date:11.08.2008
--------------------------------------------------}
function Equalop(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:Prinfo;s_inf:Pepinfo;
  varInfo:PvarInfo;
  next_str:string;{Eparr[x+1]}
  paramlist:Tlist;  {just for class instance}
  s_group:string;
begin
  if (high(Eparr)-EpInfo.x)>0 then
  if eparr[epInfo.x+1]='>' then   {detection des affectation keyvalue des composante d'un tableau}
  begin
    eval_array_keyAffect(Epinfo,Eparr,rinfo);
    exit;
  end ;


  New(s_inf);
  fillEpInfo(s_inf);

  EpInfoCopy(s_inf,EpInfo);
  //s_inf^:=EpInfo^;

  EpInfo.cmd:=Worknone;
  New(dresult);
  dresult.rtype:=rinfo.rtype;
  dresult.IntValue:=0;
  fillrinfo(dresult);
  
  //showmessage(inttostr(dresult.IntValue));
  EpInfo.y:=s_inf.y;
  //showmessage(inttostr(high(Eparr))+' '+ inttostr(EpInfo.x+1));
  if ((EpInfo.x+2)<=(high(Eparr)))  then
  begin
  next_str:= Eparr[EpInfo.x+1];
  end;
  //showmessage(Eparr[EpInfo.x]+'nextstr:'+next_str);
  {Evaluation}
  if (next_str='=') then
  begin
     EpInfo.x:=EpInfo.x+2;
     //showmessage('epinfo.y  '+inttostr(EpInfo.y)+'  '+eparr[EpInfo.y]);
     //EpInfo.y:=EpInfo.x;{ 16.10.2012 a rajouter si erreur}
     // showmessage('epinfo.y  '+inttostr(EpInfo.y)+'  '+eparr[EpInfo.y]);
  end
  else
  begin
     next_str:='';
     inc(EpInfo.x);
     EpInfo.y:=EpInfo.y;
  end;
  //showmessage( inttostr(s_inf.x+1)+' epifo.x+1  '+ inttostr( high(Eparr)));

  //showmessage('Equalop:'+inttostr(EpInfo.x));

  OperateInt(EpInfo,Eparr,dresult);
  if EpInfo.ErrId<>E_NONE then
  begin
    freerinfo(dresult);
    freeEpInfo(s_inf);
    exit;
  //showmessage(Eparr[EpInfo.errpos]+'  frer  '+epinfo.ErrParams);
  end;
  EpInfo.y:=s_inf.y;
  //showmessage('blabla'+inttostr( epInfo.x));
  //showmessage(  inttostr(epInfo.y)+' equalop '+ eparr[epInfo.y]);
   EpInfo.x:=EpInfo.x-1;  {MODIFIED 08.06.2012 if not work just reput it} 
  {/Evalutation}
  //showmessage(next_str);

  if (next_str='=') then
  begin
      // showmessage('comparaison');
      EpInfo.cmd:=s_inf.cmd;
      //if dresult.rtype=vt_char then showmessage('jkjk');
      //if rinfo.rtype=vt_none then showmessage('kjkjk');
      if CheckCompatible(rinfo,dresult,rinfo.rtype) then
      begin
         Case rinfo.rtype of
         vt_integer:
            begin
            rinfo.BoolValue:=rinfo.IntValue=dresult.IntValue;
            //showmessage('comaraison:'+inttostr(rinfo.IntValue)+'  '+inttostr(dresult.IntValue));
            end;
         vt_float:
            begin
            rinfo.BoolValue:=rinfo.floatvalue=dresult.floatvalue
            end;
         vt_char:
            begin
            //showmessage(rinfo.CharValue+'  '+dresult.CharValue);
            rinfo.BoolValue:= StrComp(rinfo.CharValue,dresult.CharValue)=0;
            end;
         vt_bool:
            begin
            rinfo.BoolValue:=rinfo.BoolValue=dresult.BoolValue
            end;
         vt_date:
            begin
            rinfo.BoolValue:=rinfo.floatvalue=dresult.floatvalue
            end;
         vt_none:
            begin
            rinfo.BoolValue:=true;
            end;
         end;
      end   else
      begin
         rinfo.BoolValue:=false;   {s'il ne sont pas de meme type c'est kil ne sont pas egales
         {SignalError(Epinfo,s_inf.x,E_OpError,''); 17.10.2012
          freerinfo(dresult);
         freeEpInfo(s_inf);  }
      end;
      rinfo.rtype:=vt_bool;
      //if rinfo.BoolValue then showmessage('oui') ;
  end
  else
  begin
     //new(varInfo);
     //showmessage('jkjk');
     if (rinfo.rtype=vt_namespaceRef) and (Eparr[EpInfo.x-1]=']') then
     begin
        s_group:=EpInfo.group;
        if assigned(EpInfo.group) then StrDispose(EpInfo.group);
        EpInfo.group:=E_STRING(rinfo.reference);
        paramlist:=Tlist.create;
        paramlist.add(rinfo.pt);
        runfunction('__array_set',EpInfo,paramlist,rinfo);
        Paramlist.free;
        strdispose(EpInfo.group);
        EpInfo.group:=E_STRING(s_group);
      end;
      varinfo:=nil;
      if (rinfo.rtype=rt_pointer) then  {cas pour les tableau}
      begin
         varinfo:=rinfo.pt;//showmessage('direct point to variable');
      end
      else
      varinfo:=getVarAdress(EpInfo.PID,rinfo.name,rinfo.group);
      if varinfo<>nil then
      begin
         {verifie les droit d'accèss  la variable}
         //if (varInfo.access=aPrivate) and (varInfo.group<>EpInfo.group) then
         if (varInfo.access=aPrivate) and (not(IsChildNamespace(epinfo.PID,EpInfo.group,varInfo.group))) then
         begin
            //showmessage(string(varInfo.group)+'   ' +string(EpInfo.group));
            SignalError(EpInfo,Epinfo.x,E_Extra,' can''t modify the private variable value');
            freerinfo(dresult);
            freeEpInfo(s_inf);
            exit;
          end;
         {processing}
         if Eparr[s_Inf.x-1]='+' then  {traitement Operateur +=}
         begin
           dresult.IntValue:=varInfo.IntValue+dresult.IntValue;
           dresult.floatvalue:=varInfo.floatvalue+dresult.floatvalue;
           strcat(varinfo.charValue,dresult.CharValue);
           RINFO_COPYTEXT(dresult,varinfo.CharValue,dresult.CharBuffSize);
           //RINFO_CATTEXT(varinfo,dresult.CharValue,dresult.CharBuffSize);
           //dresult.CharValue:=varInfo.CharValue;
         end;

         if Eparr[s_Inf.x-1]='-' then   {traitement operateur -=}
         begin
           dresult.floatvalue:=varInfo.floatvalue-dresult.floatvalue;
           dresult.IntValue:=varInfo.IntValue-dresult.IntValue;
           strcat(varinfo.charValue,dresult.CharValue);
           RINFO_COPYTEXT(dresult,varinfo.CharValue,dresult.CharBuffSize);
           //dresult.CharValue:=varInfo.CharValue;
         end;
         if (varInfo.rtype=vt_dbdata) and (rinfo.pt<>nil) then  {traitement dbdata }
         begin
           DataFunc(rinfo.pt)(workdb_setvalue,pchar(varinfo.group), Prinfo(rinfo.pt),rinfo);
         end;
         {COPIE DES VALEURS DE dresult: A revoir pour voir comment remplacer tout sa par rinfocopy}
         //showmessage(dresult.CharValue);
         varInfo.IntValue:=dresult.IntValue;
         varInfo.BoolValue:=dresult.BoolValue;
         varInfo.floatvalue:=dresult.floatvalue;
         strcopy(varInfo.CharValue,dresult.CharValue);
         RINFO_COPYTEXT(varinfo,dresult.CharValue,dresult.CharBuffSize);
         //varInfo.obj:=dresult.obj;
         if assigned(dresult.reference) then
         begin
            if assigned(varinfo.reference) then strDispose(varinfo.reference);
            varinfo.reference:=E_STRING(dresult.reference);
         end;
         varInfo.isReference:=dresult.isReference;
         varInfo.pt:=dresult.pt;
         if (varInfo.rtype=vt_null) or (varInfo.rtype=vt_none) then varinfo.rtype:=dresult.rtype;{a revoir si on veut que la variable revevant change de type automatiquement}
         //varinfo.interf:=dresult.interf;
         //varinfo.olevar:=dresult.olevar;
         //varinfo.group:=Pgstring(EpInfo.group); {evite les de modifier le propriétaire de la variable}
         {if varinfo.rtype=vt_namespaceRef then
         showmessage(varinfo.name+'  '+varinfo.group+'  '+varinfo.reference);}

         {FIN COPY DE VALEURS}
         if dresult.rtype=vt_new_class_instance then
         begin
           //SetScrNamespace(dresult.name,varInfo.name);
           varinfo.isReference:=true;
           if assigned(varinfo.reference) then StrDispose(varinfo.reference);
           varinfo.reference:=E_STRING(dresult.reference);
           varinfo.rtype:=vt_namespaceRef;
           //showmessage(varinfo.name);
           //exit;
         end;
         {reference a une fonction}
         if dresult.rtype=vt_funcRef then
         begin
            //SetScrNamespace(dresult.name,varInfo.name);
            varinfo.isReference:=true;
            if assigned(varinfo.reference) then StrDispose(varinfo.reference);
            varinfo.reference:=E_STRING(dresult.reference);
            varinfo.rtype:=vt_funcRef;
            //showmessage(varinfo.name);
            //exit;
         end;
         {tableau}
         if dresult.rtype=vt_array then
         begin
            varinfo.arrays:=dresult.arrays;
            //showmessage('jkjk_tableau');
         end;
         if varInfo.rtype=vt_null  then varInfo.rtype:=dresult.rtype;
         (*Setvar(varinfo);{obsolete}
         getVar( Eparr[s_inf.x-1],s_inf.group,varInfo) ;
         showmessage(inttostr(varInfo.IntValue)+' Var-> '+varinfo.name);
         EpInfo.x:=s_inf.y;
         showmessage(inttostr(epInfo.x)+'dfdfdf'); *)
         Epinfo.x:=EpInfo.Y {car l'instruction affection utilise toute les affectations }
     end
     else
     begin
      if s_inf.prev_traited=pt_function  then
         SignalError(Epinfo,s_inf.x,E_OpError,' Variable expected  in the left side but function found')
      else
         SignalError(Epinfo,s_inf.x,E_OpError,'');
     end;
  end;

  freeEpInfo(s_inf);
  freerinfo(dresult);
end;

{----------------Fonction comparator-----------
Fonction opératrice qui Permet de comparer 2 valeurs
symbole:x<y,x<y,x>y,x<=y,x>=y
->Date:20.07.2008
-----------------------------------------------------}
function Comparator(EPInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:Prinfo;
  s_inf:Pepinfo;
begin
  New(s_inf);
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
  {tient compte de >=;<>;<=}
  if Pos(Eparr[s_inf.x+1],'<>=')>0 then
  EpInfo.x:=EpInfo.x+2
  else
  inc(EpInfo.x);

  //EpInfo.y:=EpInfo.x;
  EpInfo.cmd:=Worknone;
  New(dresult);
  dresult.rtype:=rinfo.rtype;
  dresult.IntValue:=0;
  fillrinfo(dresult);
  OperateInt(EpInfo,Eparr,dresult);
  //if dresult.rtype=vt_char then showmessage('jkjk');
  if CheckCompatible(rinfo,dresult,rinfo.rtype) then
  begin
    //showmessage( eparr[s_inf.x]+ inttostr(rinfo.IntValue)+'  '+inttostr(dresult.IntValue));
  Case rinfo.rtype of
  vt_integer:
       begin
       {z supérieur à a}
       If (Eparr[s_inf.x]='>') then
       begin
       if  Eparr[s_inf.x+1]='=' then
          rinfo.BoolValue:=rinfo.IntValue>=dresult.IntValue
        else
          rinfo.BoolValue:=rinfo.IntValue>dresult.IntValue;
       end;
       {a inférieur à z}
       If (Eparr[s_inf.x]='<') then
       begin
       //showmessage('< eval');
        if  (Eparr[s_inf.x+1]='=') then
        rinfo.BoolValue:=rinfo.IntValue<=dresult.IntValue
        else
        if  (Eparr[s_inf.x+1]='>') then
        rinfo.BoolValue:=rinfo.IntValue<>dresult.IntValue
        else
        rinfo.BoolValue:=(rinfo.IntValue<dresult.IntValue);
      end;
      end;
  vt_float:
       begin
       {z supérieur à a}
       If (Eparr[s_inf.x]='>') then
       begin
       if  Eparr[s_inf.x+1]='=' then
          rinfo.BoolValue:=rinfo.floatvalue>=dresult.floatvalue
        else
          rinfo.BoolValue:=rinfo.floatvalue>dresult.floatvalue;
       end;
       {a inférieur à z}
       If (Eparr[s_inf.x]='<') then
       begin
       //showmessage('< eval');
        if  (Eparr[s_inf.x+1]='=') then
        rinfo.BoolValue:=rinfo.floatvalue<=dresult.floatvalue
        else
        if  (Eparr[s_inf.x+1]='>') then
        rinfo.BoolValue:=rinfo.floatvalue<>dresult.floatvalue
        else
        rinfo.BoolValue:=(rinfo.floatvalue<dresult.floatvalue);
      end;
      end;
  vt_date:
       begin
       {z supérieur à a}
       If (Eparr[s_inf.x]='>') then
       begin
       if  Eparr[s_inf.x+1]='=' then
          rinfo.BoolValue:=rinfo.floatvalue>=dresult.floatvalue
        else
          rinfo.BoolValue:=rinfo.floatvalue>dresult.floatvalue;
       end;
       {a inférieur à z}
       If (Eparr[s_inf.x]='<') then
       begin
       //showmessage('< eval');
        if  (Eparr[s_inf.x+1]='=') then
        rinfo.BoolValue:=rinfo.floatvalue<=dresult.floatvalue
        else
        if  (Eparr[s_inf.x+1]='>') then
        rinfo.BoolValue:=rinfo.floatvalue<>dresult.floatvalue
        else
        rinfo.BoolValue:=(rinfo.floatvalue<dresult.floatvalue);
      end;
      end;
  vt_char:
       begin
       {z supérieur à a}
       If (Eparr[s_inf.x]='>') then
        if  Eparr[s_inf.x+1]='=' then
          rinfo.BoolValue:=string(rinfo.CharValue)>=string(dresult.CharValue)
        else
          rinfo.BoolValue:=string(rinfo.CharValue)>string(dresult.CharValue);
       {a inférieur à z}
       If (Eparr[s_inf.x]='<') then
       if  (Eparr[s_inf.x+1]='=') then
       rinfo.BoolValue:=string(rinfo.CharValue)>=string(dresult.CharValue)
       else
       if  (Eparr[s_inf.x+1]='>') then
       rinfo.BoolValue:=string(rinfo.CharValue)<>string(dresult.CharValue)
       else
       if  (Eparr[s_inf.x+1]='=') then
       rinfo.BoolValue:=string(rinfo.CharValue)<=string(dresult.CharValue);
       end;
  end;
  end   else SignalError(Epinfo,s_inf.x,E_OpError,'');
  rinfo.rtype:=vt_bool;
  freerinfo(dresult);
  freeEpInfo(s_inf);
end;


{------------------Fonction Fieldvalue----------
Fonction opératrice qui permet d'avoir la valeur des champs
symbole:[type:table.champ]
->Date:29.07.2008
------------------------------------------------}
(*function Fieldvalue(EPInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  ListRoot:PListroot;
  table:pvtable;  g:string;
begin
  if EPInfo.ListRootStr<>'' then
  begin
  New(ListRoot);
  New(table);
  GetListRoot(EpInfo.ListRootstr,listroot);
  Getvtableinfo(listroot.mainTable,table);
  Locate(Eparr[EpInfo.x+3],table.mainfield,Epinfo.KeyValue,vt_integer);
  end;
  //showmessage('FieldValue:'+Eparr[EpInfo.x+1]);
  rinfo.rtype:=Strtortype(Eparr[EpInfo.x+1]);
  case Strtortype(Eparr[EpInfo.x+1]) of
  vt_integer:
      rinfo.IntValue:=Getintv(Eparr[EpInfo.x+3],Eparr[EpInfo.x+5]);
  vt_char:
      begin
      g:=GetStrv(Eparr[EpInfo.x+3],Eparr[EpInfo.x+5]);
      //showmessage('jkj');
      //GetMem(rinfo.CharValue,length(g));
      Strcopy(rinfo.CharValue,pchar(g)) ;
      // showmessage('fieldvalue:result='+rinfo.CharValue);
      end;
  vt_bool:
      rinfo.BoolValue:=GetBoolv(Eparr[EpInfo.x+3],Eparr[EpInfo.x+5]);
  vt_float:
      begin
      rinfo.floatvalue:=Getfloatv( Eparr[EpInfo.x+3],Eparr[EpInfo.x+5]);
      //showmessage(floattostr(rinfo.floatvalue));
     end;
  vt_date:
      rinfo.floatvalue:=Getfloatv( Eparr[EpInfo.x+3],Eparr[EpInfo.x+5]);
  end;
  epinfo.x:=Epinfo.x+6;

 
end;  *)


function ep_jkstr(str:pchar;a:integer):integer;  stdcall;
begin
Showmessage('Succès return:function jkstr:'+str);
result:=1;
end;
 {Fonction qui permet d'enregistrer les fonction}
function Reg_Functions:integer;
var
  fn:PFunc;
begin
if funcList=nil then funcList:=TList.create;
{fonction test 'h'}
new(fn);fillfunc(fn);
fn.ftype:=ft_adress;
fn.name:='h';
fn.access:=aPublic;
fn.pfunc:=@ep_h;
fn.PID:=ROOT_PID;
fn.rtype:=vt_bool ;
fn.params:=E_STRING('a:int,b:int,c:char,d:char,e:boolean');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);
{fonction test 'd'}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='d';
fn.pfunc:=@ep_d;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction test 'e'}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='e';
fn.pfunc:=@ep_e;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.rtype:=vt_none ;
fn.params:=E_STRING('');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction test 'jkstr'}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='jkstr';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@ep_JkStr;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('str:char,a:int');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de stoquer des variables char}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='sto_char';
fn.PID:=ROOT_PID;
fn.pfunc:=@sto_char;
fn.access:=aPublic;
fn.rtype:=vt_none ;
fn.params:=E_STRING('name:char,value:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de stoquer des variable integer}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='sto_int';
fn.pfunc:=@sto_int;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.rtype:=vt_none ;
fn.params:=E_STRING('name:char,value:int');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de stoquer des variable boolean}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='sto_bool';
fn.pfunc:=@sto_bool;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.rtype:=vt_none ;
fn.params:=E_STRING('name:char,value:bool');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet d'avoir la valeur d'une constante integer}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='r_int';
fn.pfunc:=@read_int;
fn.PID:=ROOT_PID;
fn.access:=apublic;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('name:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet d'avoir la valeur d'une constante integer}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='r_char';
fn.pfunc:=@read_char;
fn.access:=apublic;
fn.PID:=ROOT_PID;
fn.rtype:=vt_char ;
fn.params:=E_STRING('name:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet d'avoir la valeur d'une constante integer}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='r_bool';
fn.PID:=ROOT_PID;
fn.pfunc:=@read_bool;
fn.access:=apublic;
fn.rtype:=vt_bool ;
fn.params:=E_STRING('name:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet d'affiche un message windows}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='msgbox';
fn.pfunc:=@ep_msgbox;
fn.PID:=ROOT_PID;
fn.access:=apublic;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('title:char,text:char,flag:int');
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

//funclist.Add(fn);
{fonction qui permet d'affiche un message d'information}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='showmsg';
fn.PID:=ROOT_PID;
fn.pfunc:=@ep_msgbox;
fn.access:=apublic;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('text:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire strlen}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='strlen';
fn.PID:=ROOT_PID;
fn.pfunc:=@ep_strlen;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('str:char');
fn.access:=apublic;
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire strpos}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='strpos';
fn.PID:=ROOT_PID;
fn.access:=apublic;
fn.pfunc:=@ep_strpos;
fn.rtype:=vt_integer ;
fn.params:=E_STRING('substr:char,str:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire trim}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='trim';
fn.pfunc:=@ep_strtrim;
fn.access:=apublic;
fn.PID:=ROOT_PID;
fn.rtype:=vt_char ;
fn.params:=E_STRING('text:char');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire chr()}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='chr';
fn.PID:=ROOT_PID;
fn.pfunc:=@ep_strchr;
fn.access:=apublic;
fn.rtype:=vt_char ;
fn.params:=E_STRING('val:int');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de donner PI}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='pi';
fn.pfunc:=@ep_mathPI;
fn.rtype:=vt_float ;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.params:=E_STRING('');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire cosinus}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='cos';
fn.pfunc:=@ep_mathCos;
fn.rtype:=vt_float ;
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.params:=E_STRING('val:float');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de faire sinus}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='sin';
fn.PID:=ROOT_PID;
fn.pfunc:=@ep_mathSin;
fn.access:=aPublic;
fn.rtype:=vt_float ;
fn.params:=E_STRING('val:float');
//funclist.Add(fn);
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de  fairetan}
new(fn); fillfunc(fn);;
fn.ftype:=ft_adress;
fn.name:='tan';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@ep_mathtan;
fn.rtype:=vt_float ;
fn.params:=E_STRING('val:float');
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);


{fonction qui permet de  date}
new(fn); fillfunc(fn);;
fn.ftype:=ft_virtual2;
fn.name:='getdate';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@eval_XCommon_funcs;
fn.rtype:=vt_date ;
fn.params:=nil;
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de  time}
new(fn); fillfunc(fn);;
fn.ftype:=ft_virtual2;
fn.name:='gettime';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@eval_XCommon_funcs;
fn.rtype:=vt_date ;
fn.params:=nil;
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de  fairetan}
new(fn); fillfunc(fn);;
fn.ftype:=ft_virtual2;
fn.name:='formattime1';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@eval_XCommon_funcs;
fn.rtype:=vt_char ;
fn.params:=E_STRING('value:date');
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);

{fonction qui permet de  fairetan}
new(fn); fillfunc(fn);;
fn.ftype:=ft_virtual2;
fn.name:='formatdate1';
fn.PID:=ROOT_PID;
fn.access:=aPublic;
fn.pfunc:=@eval_XCommon_funcs;
fn.rtype:=vt_char ;
fn.params:=E_STRING('value:date');
fn.groupe:=E_STRING('');
Setfunc(fn.PID,fn,fn.name,fn.groupe);



end;
{fonction qui permet d'enregister les namespace par defautl}
function Reg_NameSpaces:integer;
var
    scr:pscrInfo;
   

begin
 if namespacelist=nil then namespacelist:=TList.Create;
 {declare global namespace}
  new(scr);
  fill_scr(scr);
  scr.Name:='';
  scr.parent:='';
  scr.PID:=ROOT_PID;
  namespacelist.Add(scr)

end;
{Fonction qui permet d'enregistrer les constantes}
function Reg_Const:integer;
var dconst:pconstinfo;
     global:PvarInfo;
     rinfo:Prinfo;
begin
if constList=nil then constList:=TList.create;
if varlist=nil then varlist:=TList.Create;
{true}
New(dconst);
dconst.name:='true';
New(dconst.rinfo);
dconst.rInfo.BoolValue:=true;
dconst.rInfo.rtype:=vt_bool;
constList.Add(dconst);
{False}
New(dconst);
dconst.name:='false';
New(dconst.rinfo);
dconst.rInfo.BoolValue:=false;
dconst.rInfo.rtype:=vt_bool;
constList.Add(dconst);

{null}
New(rinfo);
Fillrinfo(rinfo);
rinfo.name:='null';
rinfo.pID:=ROOT_PID;
rinfo.access:=apublic;
rinfo.rtype:=vt_none;
rinfo.group:=E_STRING('');
rinfo.reference:=E_STRING('');
rinfo.PID:=ROOT_PID;
varlist.Add(rinfo);


{declare global reference}
 reg_namespaces;
  new(global);
  fillRinfo(global);
  global.name:='global';
  global.group:=E_STRING('');
  global.reference:=E_STRING('');
  global.PID:=ROOT_PID;
  global.isReference:=true;
  global.rtype:=vt_namespaceref;
  varlist.Add(global)
end;

function ep_d:integer;  stdcall ;
begin
Showmessage('Succès return:function d');
result:=1;
end;

{emule strpos dans EpEval}
function ep_strpos(substr,str:pchar):pchar; stdcall;
begin
  result:=strpos(substr,str);
end;
{emule strlendans EpEval}
function ep_strlen(str:pchar):integer; stdcall;
var
  ab:pchar;
begin
  result:=strlen(str);
  ab:=ep_strchr(9);
end;
{emule strltrim dans EpEval}
function ep_strTrim(str:pchar):pchar; stdcall;
begin
  result:=Pchar(trim(str));
end;
{emule strltrim dans EpEval}
function ep_strchr(x:integer):pchar; stdcall;
var
  str:pchar;
begin

  result:=Pchar(chr(x));
  //showmessage('jkj_pchar');
end;
function ep_strReplace(str,oldPattern,newPattern:string):pchar;stdcall ;
begin
  result:=Pchar(StringReplace(str,oldpattern,newpattern,[rfReplaceAll	,rfIgnoreCase]));
end;
function ep_mathPi:double stdcall;
begin
  result:=pi;
end;

function ep_mathCos(val:double):double; stdcall;
begin

  result:=cos(val);
  //showmessage(floattostr(val));
 // result:=3.7;
end;
function ep_mathSin(val:double):double stdcall;
begin
  result:=sin(val);
end;
function ep_mathtan(val:double):double stdcall;
begin
  result:=tan(val);
end;




{-----------------envoi msg---------------}
function ep_msgbox(title,text:pchar;flag:integer):integer;  stdcall;
begin
  result:=application.messagebox(text,title,flag);
end;
function ep_showmsg(text:pchar):integer; stdcall;
begin
  result:=application.messagebox(text,'EPEVAL',0);
end;
{evalue la fonction print et echo}
function eval_echo(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
(*{permet de connaitre la limite de la fonction echo}
function GetEchoArgLimit(eparr:strarr;argBegin:integer):integer;
var
  i,a:integer;
begin
   a:=0;
   for i:=argBegin to high(eparr) do   if (eparr[i]='+') or (eparr[i]='(') then  a:=a+2;
   result:=a+argbegin;
end;
*)
function GetEchoArgLimit(eparr:strarr;argBegin:integer):integer;
const
  forbidden:array [0..1] of string=('echo','=');
var
  i,a:integer;
  gar:strarr;
begin
   a:=argBegin;
   //showmessage('hjhj'+inttostr(high(eparr))+'__argbegin'+inttostr(argbegin));
   for i:=argBegin to high(eparr) do
   begin
     if (eparr[i]=forbidden[0]) or (Eparr[i]=forbidden[1]) then
     break
     else
     inc(a);
   end;
   result:=a-1;
   //showmessage(inttostr(result));
end;


var
  dresult:prinfo;s_inf:Pepinfo;
begin
 New(s_inf);
  fillEPinfo(s_inf);
  //showmessage('hjhj');
  EpInfoCopy(s_inf,Epinfo);
  s_inf.cmd:=worknone;
  inc(s_inf.x);
  s_inf.y:=GetEchoArgLimit(eparr,s_inf.x);
//  showmessage('echo methode:  '+eparr[s_inf.x]+'  '+Eparr[s_inf.y]);
 if ((Epinfo.prev_traited<>pt_none) and (EpInfo.prev_traited<>pt_operator))then  {verifie que la colonne précédante est un opérateur}
  begin
    SignalError(EpInfo,EpInfo.x,E_PERSONAL,pgstring('Missing semi column( ;) after "'+Eparr[Epinfo.x-1]+'"'));
    EpInfo.x:=EpInfo.x+1;
    freeEpInfo(s_inf);
    exit;
  end;
   New(dresult);
   fillrinfo(dresult);
  s_inf.BreakChar:='echo';
  //showmessage(Eparr[s_inf.x]);
  Operateint(s_inf,Eparr,dresult);

  if (s_inf.ErrId<>E_None) then
  begin

   { EpInfo.ErrId:=s_inf.ErrId;
    Epinfo.ErrParams:=s_inf.ErrParams;
    EpInfo.ErrDeclationMode:=s_inf.ErrDeclationMode;
    EpInfo.ErrNamespace:=s_inf.ErrNamespace;
    EpInfo.ErrPos:=s_inf.ErrPos;
    }
    copyEpError(s_inf,EpInfo);
    //showmessage('jkjk_error');
    exit;
  end;
  if (high(Eparr)-s_inf.x)>-1 then
  if Eparr[s_inf.x]='echo' then
  begin
  SignalError(EpInfo,s_inf.x,E_PERSONAL,pgstring('Missing semi column( ;) after "'+Eparr[s_inf.x]+'"'));
  exit;
  end;
  Epinfo.x:=s_inf.x-1;
  //showmessage('echo charval'+dresult.CharValue);

  //showmessage(inttostr(dresult.rtype));

  //application.MessageBox(Pchar(cnv_rinfoTostr(dresult)),'Information Epeval',0);
  //printScreenText(epInfo.PID,cnv_rinfoTostr(dresult));
  printScreenText2(epInfo.PID,pchar(cnv_rinfoTostr(dresult)));
  result:=0;
  //showmessage('jhj');
  freerInfo(dresult);
  freeEpInfo(s_inf);

end;

{-----------------fin envoi msg---------------}
procedure ep_e; stdcall;
begin
showmessage('succès return:function e');
end;

{exemple de fonction}
function ep_h(a,b:integer;c,d:Pchar;e:boolean):boolean; stdcall;
begin

showmessage('success function:'+inttostr(a)+'___'+inttostr(b));
{showmessage('Success function:'+c+'__'+d);
if e then
showmessage('success function:vrai')
else
showmessage('success function:faux'); }
//result:=Pchar('Jacob ouaiiiii ');
//result:=5.2
result:=false;
end;
{Permet d'ajouter une function}
procedure AddEpFunc(Func:Pfunc);stdcall;
begin
funclist.Add(func);
end;
{Permet d'ajouter une constante}
procedure AddEpConst(EpConst:PConstInfo);stdcall;
begin
constlist.Add(epconst)
end;



function eval_up(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:Prinfo;
  s_inf:PepInfo;
  i:integer;
begin
  if rinfo.rtype=vt_char then
  begin
    Jk_StrPos(EpInfo,Eparr,rinfo);
    exit;
  end
  else
  begin
     New(dresult);
     Fillrinfo(dresult);
     New(s_inf);
     fillEpInfo(s_inf);
     EpInfoCopy(s_inf,EpInfo);
     inc(s_inf.x);
     s_inf.Y:=s_inf.x;
     OperateInt(s_inf,Eparr,dresult);
     rinfo.floatvalue:= Power(rinfo.floatvalue,dresult.floatvalue);
     rinfo.IntValue:=round(rinfo.floatvalue);
     rinfo.rtype:=vt_float;
     freerinfo(dresult);
     Epinfo.x:=s_inf.x;
     freeEpinfo(s_inf);
  end;


end;


{------------------Fonction diviser ?????----------
fonction opératrice qui permet de diviser
->Date:19.07.2008
----------------------------------------------}

function Jk_StrPos(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin
  New(dresult);New(s_inf);
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);//s_inf^:=Epinfo^;
  Epinfo.cmd:=worknone;
  inc(Epinfo.x);
  Epinfo.y:=EpInfo.x;
  FillrInfo(dresult);
  //showmessage('diviser');
  if (operateint(Epinfo,Eparr,dresult)=0) then
  begin
    if CheckCompatible(rinfo,dresult,vt_char) then
    begin
    rInfo.BoolValue:=(StrPos(Strlower(rinfo.CharValue),Strlower(dresult.CharValue))>nil);
    end
    else
    rinfo.ErrId:=dresult.ErrId;
  Epinfo.y:=s_inf.y;
  EpInfo.x:=Epinfo.x-1;
  Epinfo.cmd:=s_inf.cmd;
  freeEpInfo(s_inf);
  freerInfo(dresult);
  //showmessage('kjjjk')
  end;
end;

{fonction qui permet d'ajouter une constant integer}
procedure Sto_int(Name:Pchar;value:integer);stdcall;
var
  Cst:PConstInfo;
begin
  new(Cst);
  New(Cst.rInfo);
  Cst.groupe:='';
  Cst.name:=Name;
  FillrInfo(Cst.rInfo);
  Cst.rInfo.IntValue:=value;
  cst.rInfo.rtype:=vt_integer;
  AddEpConst(Cst);
end;

{fonction qui permet d'ajouter une constant integer}
procedure Sto_char(Name:Pchar;value:Pchar)stdcall;
var
  Cst:PConstInfo;
begin
  new(Cst);
  New(Cst.rInfo);
  Cst.groupe:='';
  Cst.name:=Name;
  FillrInfo(Cst.rInfo);
  cst.rInfo.rtype:=vt_char;
  StrCopy(Cst.rInfo.CharValue,value);
  AddEpConst(Cst);
end;

{fonction qui permet d'ajouter une constant integer}
procedure Sto_bool(Name:pchar;value:boolean)stdcall;
var
  Cst:PConstInfo;
begin
  new(Cst);
  New(Cst.rInfo);
  Cst.groupe:='';
  Cst.name:=Name;
  FillrInfo(Cst.rInfo);
  Cst.rInfo.BoolValue:=value;
  cst.rInfo.rtype:=vt_bool;
  AddEpConst(Cst);
end;
{Fonction qui permet d'obtenir la valeur d'une const Ep numerique}
function read_int(name:pchar):integer; stdcall;
var
  Cst:PConstInfo;
begin
  new(cst);
  if GetConst(name,'',Cst)=0 then
  result:=cst.rinfo.IntValue
  else
  ShowMessage('Contant inconue:'+name);
end;
{Fonction qui permet d'obtenir la valeur d'une const Ep char}
function read_char(name:pchar):Pchar; stdcall;
var
  Cst:PConstInfo;
begin
  new(cst);
  if GetConst(name,'',Cst)=0 then
  begin
  result:=stralloc(255);
  Strcopy(cst.rinfo.CharValue,result)
  end
  else
  ShowMessage('Contant inconue:'+name);
end;
{Fonction qui permet d'obtenir la valeur d'une const Ep boolean}
function read_bool(name:pchar):boolean; stdcall;
var
  Cst:PConstInfo;
begin
  new(cst);
 if GetConst(name,'',Cst)=0 then
  result:=cst.rinfo.BoolValue
 else
 ShowMessage('Contant inconue:'+name);
end;


{  Evalue les incrementations
principe:}
function eval_inc_dec(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  rvar:PvarInfo;
begin
 //showmessage('inc');
  new(rvar);
  fillrinfo(rvar);
  if ((eparr[epInfo.x]='+') and (Eparr[Epinfo.x+1]='+')) then
  begin
      Getvar(EpInfo.PID,Eparr[epInfo.x-1],EpInfo.group,rvar);
      inc(rvar.IntValue);
      rvar.floatvalue:=rvar.IntValue;
      rinfo.intvalue:=rvar.intvalue;
      rinfo.floatvalue:=rvar.floatvalue;
      //rvar.rtype:=vt_integer;
      Setvar(EPInfo.PID,rvar,true);
      EpInfo.x:=EpInfo.x+1;
      //showmessage(inttostr(rvar.rtype));

  end;
  if ((eparr[epInfo.x]='-') and (Eparr[Epinfo.x+1]='-')) then
  begin
      Getvar(EpInfo.PID,Eparr[epInfo.x-1],EpInfo.group,rvar);
     // showmessage(inttostr(rvar.IntValue));
      dec(rvar.IntValue);
      rvar.floatvalue:=rvar.IntValue;
      rinfo.intvalue:=rvar.intvalue;
      rinfo.floatvalue:=rvar.floatvalue;
      Setvar(EpInfo.PID,rvar,true);
      EpInfo.x:=EpInfo.x+1;
  end;
end;


{  Ajoute  une variable   une valeur ajouté à l'ancienne valeur de la variable .
Principe:Ajoute une la valeur dans rinfo afin que l'évaluateur de "equalop" puis additionner
l'ancienne valeur à la nouvelle valeur:faux

methote obsolete 19.09.2010}
function eval_preconcat(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  varInfo:PvarInfo;
  dresult:prinfo;s_info:pepInfo;
begin
 if (Eparr[EpInfo.x]='&') and  (Eparr[EpInfo.x+1]='=')  then
  begin
  new(s_info);
  fillEpInfo(s_info);
  EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^;
  new(dresult);
  FillrInfo(dresult);
  s_info.x:=EpInfo.x+2;
  new(varInfo);
  fillrinfo(varinfo);
  if (getvar(EPInfo.PID,Eparr[EpInfo.x-1],EpInfo.group,varInfo))=0 then
  begin
      {effectue presque la même chose que dans evalop sauf que concatenation}
      //showmessage('jkj'+inttostr(s_info.x)+'  '+eparr[s_info.x]);
      operateint(s_info,Eparr,dresult);
       
      EpInfo.x:=s_info.x-1;
      varInfo.IntValue:=varInfo.IntValue+dresult.IntValue;
      if strlen(varInfo.CharValue)>0 then strcat(varInfo.CharValue,dresult.CharValue);
      varInfo.floatvalue:=dresult.floatvalue+varInfo.floatvalue;
      varInfo.BoolValue:=dresult.BoolValue;{on ne peut additonnez des booleans}
      //varInfo.obj:=dresult.obj; {on ne peut additonnez des objet}
      varInfo.pt:=dresult.pt    {on ne peut additonnez des pointer};
      //rInfo^:=varInfo^;
      rInfoCopy(rInfo,varInfo);
      if varInfo.rtype=vt_none  then varInfo.rtype:=dresult.rtype;
      Setvar(EPInfo.PID,varinfo);
  end
  else
  begin
    SignalError(Epinfo,s_info.x,E_OpError,'');
    freerinfo(varinfo);
  end;
  freeEpInfo(s_info);
end;

end;

{function eval_dbquery(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  varInfo:PvarInfo;
  dresult:prinfo;s_info:pepInfo;
  dbdata:prinfo;
begin          
  new(s_info);
  new(dresult);
  new(dbdata);
  Fillrinfo(dresult);
  s_info^:=EpInfo^;
  inc(s_info.x);
  s_info.y:=s_info.x;
  Operateint(s_info,eparr,dresult);
 // showmessage(dresult.CharValue);
  ado_query(dresult.CharValue,dbdata);
  rinfo^:=dbdata^;
  rInfo.rtype:=vt_dbdata;
  epInfo.x:=s_info.x-1;
end; }
{fonction qui permet d'évaluer la fonction qui permet de créer un tableau}
function eval_array_Func(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  Pend:integer;
  i:integer;
  s_inf:PEpInfo;
  param:Prinfo;
  IntKey,KeyIndex:integer;
  keyname:string;
begin
  pend:=GetParaEnd(Eparr,EPInfo.x+1);
  if pend=-1 then
  begin
  signalError(EpInfo,EpInfo.x,E_NOPARAEND,'');
  exit;
  end;
  new(s_inf);
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
  s_inf.x:=s_inf.x+2;
  s_inf.y:=pend-1;
  while not  (s_inf.x>s_inf.y) do
  begin
      New(Param);
      // Param^:=pparamInfo(ParamList[i])^;
      fillrinfo(param);
      s_inf.cmd:=workuntil ;
      s_inf.cArg1:=',';
      OperateInt(s_Inf,EPArr,Param);
      if s_inf.ErrId<>E_NONE then
      begin
        copyEpError(s_inf,EPInfo);
        exit;
      end;
      keyIndex:=-1; keyname:=param.key;
      for i:=0 to high(rinfo.arrays) do
      if Prinfo(rinfo.arrays[i]).name=keyname then
      begin
        keyIndex:=i;
        break;
      end;
      if keyIndex=-1 then
      begin
        intkey:=-1;
        if (isnumeric(keyname)) or (trim(keyname)='') then
        begin
          for i:=0 to high(rinfo.arrays)do
            if isNumeric(Prinfo(rinfo.arrays[i]).name) then
            if strtoint(Prinfo(rinfo.arrays[i]).name)>intkey   then
            begin
            intkey:=strtoint(Prinfo(rinfo.arrays[i]).name);
            end;
            inc(intkey);
            keyname:=inttostr(intKey);
        end;

        strcopy(param.name,PevChar(keyname));

        SetLength(rinfo.arrays,length(rinfo.arrays)+1) ;
        
        keyindex:=high(rinfo.arrays);
        
      end;
      rinfo.arrays[keyindex]:=param;
      Inc(s_inf.x);

  end;
   EpInfo.x:=pend+1;
   rinfo.rtype:=vt_array;
   freeEpInfo(s_inf);
end;

function eval_array_keyAffect(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_info:pepInfo;
  segEnd:integer;
  str,keyname:string;
  i,keyId:integer;
begin
  if not((Eparr[EpInfo.x]='=') and (eparr[EpInfo.x+1]='>')) then
  begin
  signalError(EpInfo,Epinfo.x,E_SYNTAX,'array key affect error');
  exit;
  end;
  new(s_info);
  new(dresult);
  fillrinfo(dresult);
  fillEPInfo(s_info);
  EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^; {ici on suppose que la commande workuntil "," est active}
  s_info.cmd:=workuntil;
  s_info.cArg1:=',';
  s_info.x:=s_info.x+2;
  //showmessage(eparr[s_info.x-1]);
  operateint(s_info,eparr,dresult);
  if s_info.ErrId<>E_none then
  begin
    copyEpError(s_info,epinfo);
    exit;
  end;
  if rinfo.rtype=vt_integer then keyname:=inttostr(rinfo.IntValue)
  else
  if rinfo.rtype=vt_char then keyname:=rinfo.CharValue
  else
  begin
    signalError(EpInfo,Epinfo.x,E_SYNTAX,'array key affect error. key must be string or integer');
    exit;
  end;
  rinfoCopy(rinfo,dresult);//rinfo^:=dresult^;
  strcopy(rinfo.key,Pchar(keyname));
  Epinfo.x:=s_info.x-1;
  freeEpInfo(s_info);
  freeRinfo(dresult);

end;

function eval_array_value(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  varInfo:PvarInfo;
  dresult:prinfo;s_info:pepInfo;
  segEnd:integer;
  str,keyname:string;
  i,keyId,intkey:integer;
  tableau:Prinfo;
begin
  new(s_info);  new(dresult);
  Fillrinfo(dresult);
  FillEpInfo(s_info);
  segEnd:=GetBlocEnd_EP(Eparr,EpInfo.x,'[',']');
  EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^;
  inc(s_info.x);
  s_info.y:=segEnd-1;
  Operateint(s_info,eparr,dresult);
  if s_info.ErrId<>E_NONE then
  begin
    copyEPError(s_info,EpInfo);
    exit;
  end;
  if (dresult.rtype=vt_integer) then
    keyname:=inttostr(dresult.IntValue)
  else
  if (dresult.rtype=vt_char) then
    keyname:=dresult.charvalue
  else
  begin
    signalError(EpInfo,EpInfo.x,EpInfo.ErrId,'the key of a an array must be a char or a int');
  end;

  if rinfo.rtype<>rt_pointer then
  begin
    SignalError(EpInfo,EPInfo.x,E_SYNTAX,'Segment must be placed after array or functin');
    exit;
  end;
     tableau:=rinfo.pt;
     keyId:=-1;
     for i:=0 to high(tableau.arrays) do
     begin
     //showmessage(tableau.arrays[i].name+'____'+keyname);
     if  (tableau.arrays[i].name=keyname) then
     begin
        keyId:=i;
        //showmessage(tableau.arrays[i].name+'____'+keyname);
     end;
     end;
     if keyId=-1 then
     begin
       intkey:=-1;
       if isnumeric(keyname) then
       begin
       for i:=0 to high(tableau.arrays) do
         if isnumeric(tableau.arrays[i].name)      then
         if strtoint(tableau.arrays[i].name)>keyId then
         intkey:=strtoint(tableau.arrays[i].name);
       inc(intkey);
       keyname:=inttostr(intkey);
       end;
         setlength(tableau.arrays,length(tableau.arrays)+1);
         keyId:=high(tableau.arrays);
         new(varinfo);
         fillrinfo(varinfo);
         strcopy(varinfo.name,Pevchar(keyname));
         tableau.arrays[keyid]:=varinfo;
         //showmessage('jkjè___'+eparr[SegEnd+1]);
     end;

     //rinfo^:=tableau.arrays[keyid]^;  
     rinfoCopy(rinfo,tableau.arrays[keyid]);{par defaut}
     {valeur différente des rinfo si l'expressio suivante est un operateur}
     if high(Eparr)>=Segend+2 then
     if (eparr[SegEnd+1]='=') and(Eparr[SegEnd+2]<>'=') then
     begin
       rinfo.rtype:=rt_pointer;
       rinfo.pt:=tableau.arrays[keyid];
     end
     else
     if (eparr[SegEnd+1]='[')  then
     begin
       rinfo.rtype:=rt_pointer;
       rinfo.pt:=tableau.arrays[keyid];
     end;



  //showmessage(eparr[epinfo.x]);
  EpInfo.x:=segEnd;
  FreeEpInfo(s_info);
  FreeRinfo(dresult);
 
end;
{
function eval_data(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  varInfo:PvarInfo;
  dresult:prinfo;s_info:pepInfo;

  segEnd:integer;
  donnee:variant;
  str:string;
begin
  new(s_info);  new(dresult);
  Fillrinfo(dresult);
  segEnd:=GetBlocEnd_EP(Eparr,EpInfo.x,'[',']');
  s_info^:=EpInfo^;
  inc(s_info.x);
  s_info.y:=segEnd-1;

  Operateint(s_info,eparr,dresult);
  EpInfo.x:=segEnd;
  donnee:=ado_data(dresult.CharValue,rinfo);
  if  not VarIsEmpty(donnee) then
  begin
 // showmessage(Eparr[s_info.x]+'  '+donnee);
  if  VarIsNumeric(donnee) then
  begin
  rinfo.IntValue:=donnee;
  rinfo.floatvalue:=donnee;
  end;        
  str:=donnee;
  //showmessage(str);
  rinfo.CharValue:=stralloc(6550);
  strcopy(rinfo.CharValue,Pchar(str));
                 //   showmessage('hjhj');
  if  VarIsOrdinal(donnee) then
  begin
  rinfo.BoolValue:=donnee;
  rinfo.IntValue:=donnee;

  end;
    rinfo.rtype:=vt_char;
  end;


end;
}
{Evalue un segment marqué par [ . }
function eval_segment(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  child,myVar:Prinfo; i:integer;
  dresult:Prinfo;
  s_info:PEpInfo;
  segEnd:integer;
  s_group:string;
  paramlist:TList;{just for namespace ref}

begin
   if (rInfo.rtype=vt_array) then
   begin
       //showmessage('is array');
       if ((EpInfo.x-1)<0) or ((EpInfo.x+2)>high(Eparr)) then
       SignalError(EPInfo,EpInfo.x,E_PERSONAL,'utilisation incorrect  "["')
       else
       if  not isnumeric(Eparr[EpInfo.x+1]) then
       SignalError(EPInfo,EpInfo.x,E_PERSONAL,'utilisation incorrect de "[<numeric>]"')
       else
       if (Eparr[EpInfo.x+2]<>']') then
       SignalError(EPInfo,EpInfo.x,E_PERSONAL,'utilisation incorrect de "["');
       if EpInfo.ErrId<>E_NONE then exit;

       
      {
       child:=rinfo.child;
       i:=0;
       while not (strtoInt(Eparr[EpInfo.x+1])>i) do
       begin
         if (strtoInt(Eparr[EpInfo.x+1])=i) then
         begin
         rinfo:=child;
         //rinfo.child:=nil;
         break;
         end
         else
         child:=child.child;
         if child=nil then
         begin
           new(myVar);
           Fillrinfo(myVar);
           child.child:=myVar;
           child.rtype:=vt_array_row;
         end;
        


         inc(i);
       end;
       EpInfo.x:=EpInfo.x+2;
       }
   end;
   //showmessage(eparr[epInfo.x-1]);
   if (rInfo.rtype=vt_dbdata) or (rinfo.rtype=vt_namespaceRef) then
   begin
       {traiment spécial pour la base de donné}
       //showmessage('is data array');
       if rinfo.rtype=vt_namespaceRef then
       if (GetscrInfotype(epInfo.PID,rinfo.reference)<>scr_class_instance)  then
       begin
         SignalError(EpInfo,EpInfo.x,E_PERSONAL,'Syntax Error');
         epinfo.traited:=true;
         exit;
       end;

       new(s_info);new(dresult);
       fillEpInfo(s_info);
       Fillrinfo(dresult);
       segEnd:=GetBlocEnd_EP(Eparr,EpInfo.x,'[',']');
       EpInfoCopy(s_info,EpInfo);
       //showmessage(s_info.group);
       inc(s_info.x);
       s_info.y:=segEnd-1;
       s_info.cmd:=worknone;
       Operateint(s_info,eparr,dresult);
       epInfo.x:=segEnd;
       if s_info.ErrId<>E_NONE then
       begin
        copyEPError(s_info,EpInfo);
        //showmessage('jhjh');
        exit;
       end;
       if not( (dresult.rtype=vt_integer)or (dresult.rtype=vt_char)) then
       begin
         signalError(EpInfo,EpInfo.x,E_PERSONAL,'the key of a an array must be a char or a int');
         exit;
       end;
       if ((high(eparr)-epInfo.x)>=2) then
       if (eparr[epInfo.x+1]='=') and (eparr[epInfo.x+2]<>'=')then
       begin
       //rinfo.rtype:=t_pointer;
         rinfo.pt:=dresult;
         exit;
       end;
       //showmessage('segment group:'+rinfo.group);
       case rinfo.rtype of
       vt_dbdata:
             begin
               DataFunc(rinfo.pt)(workdb_getvalue,pchar(rinfo.group), dresult,rinfo);
               if assigned(dresult) then freeRInfo(dresult);
             end;
       vt_namespaceRef:
             begin
             s_group:=EpInfo.group;
             EpInfo.group:=E_STRING(rinfo.reference) ;
             paramlist:=Tlist.create;
             paramlist.add(dresult);
             RunFunction('__array_getvalue',EpInfo,paramlist,rinfo);
             EpInfo.group:=E_STRING(s_group);
             paramlist.free;
             end;
       end;
      //StrDispose(dresult.CharValue);

      freeEpInfo(s_info);
   //eval_data(EpInfo,Eparr,rInfo);
   end
   else
   begin
   //showmessage('rinfo.name:'+rinfo.name+'  '+eparr[epinfo.x]);
   eval_array_value(EpInfo,Eparr,rinfo);
   //Fieldvalue(EPInfo,Eparr,rinfo);
   end;
end;

{evalue l'operateur '->' .Depend de l'evaluteur de soustraction
29.08.2010 00:01 mn}
function eval_affect_fleche(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   scr:PscrInfo;
begin
  if (Eparr[EpInfo.x]='_') and (EpInfo.x+1>high(Eparr)) then
  begin
  signalError(EpInfo,EpInfo.x,E_Syntax,'');
  exit;
  end;
  if (Eparr[EpInfo.x]='-') and (Eparr[EpInfo.x+1]='>') and(rinfo.rtype<>vt_namespaceRef) then
  begin
  signalError(EpInfo,EpInfo.x,E_Syntax,'');
  exit;
  end;
  if rinfo.rtype=vt_namespaceRef then inc(EpInfo.x);
end;
{fonction qui permet d'évaluer la définition du type d'acces pour les variables et fonctions}
function Eval_access_right(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  if (Eparr[EPInfo.x]='public') then
  begin
    rinfo.access:=apublic;
    rinfo.name:='public';
    rinfo.reference:=E_STRING('public');
    rinfo.rtype:=vt_none;
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='private') then
  begin
    rinfo.access:=aprivate;
    rinfo.name:='private';
    rinfo.rtype:=vt_none;
    rinfo.reference:=E_STRING('private');
    rinfo.Isreference:=true;
  end;
end;
{fonction qui permet d'évaluter les types des nouvelles definitions de variables}
function Eval_type(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  if (Eparr[EPInfo.x]='int') then
  begin
    rinfo.rtype:=vt_integer;
    rinfo.name:='typedef';
    rinfo.reference:=E_STRING('typedef');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='float') then
  begin
    rinfo.rtype:=vt_float;
    rinfo.name:='typedef';
    rinfo.reference:=E_STRING('typedef');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='char') then
  begin
    rinfo.rtype:=vt_char;
    rinfo.name:='typedef';
    rinfo.reference:=E_STRING('typedef');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='date') then
  begin
    rinfo.rtype:=vt_date ;
    rinfo.name:='typedef';
    rinfo.reference:=E_STRING('typedef');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='array') then
  begin
    rinfo.rtype:=vt_array;
    rinfo.name:='typedef';
    rinfo.reference:=E_STRING('typedef');
    rinfo.Isreference:=true;
  end
end;
function Eval_Scr_privilege(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  if (Eparr[EPInfo.x]='__ADMIN__') then
  begin
    rinfo.name:='__ADMIN__';
    rinfo.reference:=E_STRING('_ADMIN__');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='__INVITE__') then
  begin
    rinfo.name:='__INVITE__';
    rinfo.reference:=E_STRING('__INVITE__');
    rinfo.Isreference:=true;
  end
  else
  if (Eparr[EPInfo.x]='__SUPADMIN__') then
  begin
    rinfo.name:='__SUPADMIN__';
    rinfo.reference:=E_STRING('__SUPADMIN__');
    rinfo.Isreference:=true;
  end;

end;
function eval_printedText(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  if (high(eparr)-EpInfo.x)>0 then
  if (Eparr[EpInfo.x+1]<>'<?') then
  begin
     //showmessage('PRINTED TEXT___'+Eparr[EpInfo.x+1]);
     PrintScreenText(epInfo.PID,Eparr[EpInfo.x+1]);
     EpInfo.x:=EpInfo.x+1;

  end;
  EpInfo.x:=EpInfo.x+1;
end;
{évalue une reference: a revoir}
function eval_ref(EpInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;
begin

end;

{fonction qui permet d'évaluer la fonction qui permet de créer un tableau}
function eval_isset(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin
  New(s_inf);
  fillEPinfo(s_inf);
  EpInfoCopy(s_inf,Epinfo);
  s_inf.cmd:=worknone;
  inc(s_inf.x);
  s_inf.y:=GetParaEnd(eparr,s_inf.x);
  New(dresult);
  fillrinfo(dresult);
  s_inf.silentMode:=true;
  Operateint(s_inf,Eparr,dresult);
  rinfo.rtype:=vt_bool;
  case s_inf.ErrId of
  E_unKnowSymbol:
      begin
      rinfo.BoolValue:=false;
      end;
  E_NONE:
      begin
       rinfo.BoolValue:=true;
      end;
  else
     begin
       CopyEpError(s_inf,EpInfo);
     end;
  end;
  Epinfo.x:=s_inf.y;
  freeEpInfo(s_inf);
  freeRinfo(dresult);


end;

{fonction qui permet de faire une somme de fonction f(x)}
procedure eval_Xcommon_funcs(PID:integer;func:pfunc;ruInfo:pointer;result:Prinfo;EPInfo:pointer);stdcall;
var
  pend,i,v:integer;
  init,fin:integer;
  dresult,value,x:prinfo;
  s_inf:Pepinfo;
begin
  if func.name='getdate' then
  begin
    result.floatvalue:=date;
    result.rtype:=vt_date;
  end;
  if func.name='formatdate1' then
  begin
    result.rtype:=vt_char;
    value:=GetFuncParam(PID,'value',epInfo);
    RINFO_COPYTEXT(result,PAnsiChar(DateToStr(value.floatvalue)));
  end;
  if func.name='formattime1' then
  begin
    value:=GetFuncParam(PID,'value',epInfo);
    result.rtype:=vt_char;
    RINFO_COPYTEXT(result,PAnsiChar(DateTimeToStr(value.floatvalue)));
  end;

  if func.name='gettime' then
  begin
    result.floatvalue:=time;
    result.rtype:=vt_date;
  end;
end;

{fonction qui permet de faire une somme de fonction f(x)}
function eval_SUMFX(EPInfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  pend,i,v:integer;
  init,fin:integer;
  dresult,x:prinfo;
  s_inf:Pepinfo;


begin
   pend:=GetParaEnd(Eparr,EpInfo.x);
   {looking for the last ; }
   v:=-1;
   for i:=high(Eparr) downto EpInfo.x+1 do
   if (Eparr[i]=';') then
   begin
      v:=i;
      break;
   end;
   if v=-1 then
   begin
     SignalError(EpInfo,EpInfo.x,E_SYNTAX,'anormal use of sumFx');
     Exit;
   end;
   {rechercher du debut et fin de literation}
   init:=StrToInt(Eparr[v+1]);
   fin:=StrToInt(Eparr[v+3]);
   {running function}
   New(s_inf);
   new(dresult);
   Fillrinfo(dresult);
   fillEPinfo(s_inf);
   new(x);
   Fillrinfo(x);
   x.rtype:=vt_integer;
   x.name:='x';
   //x.group:=E_STRING(epinfo.group);
   Setvar(EpInfo.PID,x,false);
   for i:=init to fin do
   begin
      x.IntValue:=i;
      x.floatvalue:=x.Intvalue;
      EpInfoCopy(s_inf,Epinfo);
      s_inf.cmd:=worknone;
      s_inf.x:=EpInfo.x+2;
      s_inf.y:=v-1;
      Operateint(s_inf,Eparr,dresult);
      if (s_inf.ErrId<>vt_none) then
      begin
        CopyEpError(s_inf,EpInfo);
        break;
      end;
      rinfo.floatvalue:=dresult.floatvalue+rinfo.floatvalue;
      rinfo.rtype:=vt_float;
      rinfo.IntValue:=round(rinfo.floatvalue);

   end;
   Freerinfo(dresult);
   UnsetVar(EpInfo.PID,'x',epInfo.group);
   Epinfo.traited:=true;
   Epinfo.x:=Pend;

end;

{fonction qui permet de traiter les operateur boolean: and ,or, xor}
function eval_StandartBoolOperator(EpInfo:PepInfo;Eparr:Strarr;rInfo:PrInfo):integer;
var
  dresult:Prinfo;
  s_inf:Pepinfo;
begin
  New(s_inf);
  New(dresult);
  fillEpInfo(s_inf);
  fillrinfo(dresult);

  EpInfoCopy(s_inf,EpInfo);
  inc(s_inf.x);
  s_inf.y:=s_inf.x;
  EpInfo.cmd:=Worknone;
  OperateInt(s_inf,Eparr,dresult);

  if CheckCompatible(rinfo,dresult,vt_bool) then
  begin
    if (Eparr[EpInfo.x]='and') or (Eparr[EpInfo.x]='&&') then
    begin
     rinfo.BoolValue:=(rinfo.BoolValue=dresult.BoolValue) and (rinfo.BoolValue=true);
    end
    else
    if (Eparr[EpInfo.x]='or') or (Eparr[EpInfo.x]='||') then
    begin
     rinfo.BoolValue:=(rinfo.BoolValue=true) or (dresult.BoolValue=true);
    end

    else
    if (Eparr[EpInfo.x]='xor')  or (Eparr[EpInfo.x]='') then
    begin
     rinfo.BoolValue:=(rinfo.BoolValue=true) xor (dresult.BoolValue=true);
    end



  end
  else
  begin
     SignalError(EpInfo,epinfo.x,E_OpError,'');
  end;
  EpInfo.x:=s_inf.x;
  freerinfo(dresult);
  freeEpInfo(s_inf);
end;




{Fonction qui permet d'enregistrer tout les opérateurs par défaut}
function Reg_Operators:integer;
var
  op:Poperator;
begin
  {lecture du lefOp \=privé de ;=separateur}
  if OperatorList=nil then OperatorList:=TList.Create;
  {addition}
  new(op);
  op.name:='+' ;
  op.Pop:=@add;
  op.leftOp:='=;+;(;";''';
  OperatorList.Add(op);
  {Soustraction}
  New(op);
  op.name:='-';
  op.Pop:=@Substract;
  //op.leftOp:='-;=;(;';
  op.leftOp:='*';
  OperatorList.Add(op);
  {Division}
  New(op);
  op.name:='/';
  op.Pop:=@divise;
  op.leftOp:='=;(';
  OperatorList.Add(op);
  {Multiplication}
  New(op);
  op.name:='*';
  op.Pop:=@Multiply;
  op.leftOp:='=;(';
  OperatorList.Add(op);
  {Paranthèse}
  New(op);
  op.name:='(';
  op.Pop:=@Paranthese;
  op.leftOp:='*\"';
  OperatorList.Add(op);
  {Concact string}
  New(op);
  op.name:='&';
  op.Pop:=@dconcact;
  op.leftOp:='*';
  OperatorList.Add(op);
  {indicateur de valeur charactère}
  New(op);
  op.name:='"';
  op.Pop:=@Selstr;
  op.leftOp:='*\(';
  OperatorList.Add(op);
  {comparator <}
   New(op);
  op.name:='<';
  op.Pop:=@Comparator;
  op.leftOp:='(;"';
  OperatorList.Add(op);
  {comparator >}
   New(op);
  op.name:='>';
  op.Pop:=@Comparator;
  op.leftOp:='(;";=;-';
  OperatorList.Add(op);
   {Acces aux valeurs des champs}
   New(op);
  op.name:='[';
  op.Pop:=@eval_segment;
  op.leftOp:='*';
  OperatorList.Add(op);
   {Acces aux valeurs des champs  }
   New(op);
  op.name:='=';
  op.leftOp:='";=;<;>;+;-;!;';
  op.Pop:=@EqualOp;
  OperatorList.Add(op);
  {Position d'une chaine dans une autre chaine (^=pos) }
  New(op);
  op.name:='^';
  op.Pop:=@eval_up;
  op.leftOp:='"';
  OperatorList.Add(op);
  {Evaluation de echo }
  New(op);
  op.name:='echo';
  op.leftOp:='*';
  op.Pop:=@eval_echo;
  OperatorList.Add(op);
  (*{Evaluation de dbquery }
  New(op);
  op.name:='db_query';
  op.Pop:=@eval_dbquery;
  OperatorList.Add(op);
  *)
  {Evaluation de pulic }
  New(op);
  op.name:='public';
  op.leftOp:='';
  op.Pop:=@eval_access_right;
  OperatorList.Add(op);
  {Evaluation de private }
  New(op);
  op.name:='private';
  op.leftOp:='';
  op.Pop:=@eval_access_right;
  OperatorList.Add(op);
  {Evaluation de array }
  New(op);
  op.name:='array';
  op.leftOp:='=';
  op.Pop:=@eval_array_func;
  OperatorList.Add(op);
  {Evaluation de int }
  New(op);
  op.name:='int';
  op.leftOp:='';
  op.Pop:=@eval_type;
  OperatorList.Add(op);
  {Evaluation de int }
  New(op);
  op.name:='float';
  op.leftOp:='';
  op.Pop:=@eval_type;
  OperatorList.Add(op);
  {Evaluation de int }
  New(op);
  op.name:='char';
  op.leftOp:='';
  op.Pop:=@eval_type;
  OperatorList.Add(op);
  {Evaluation de int }
  New(op);
  op.name:='date';
  op.leftOp:='';
  op.Pop:=@eval_type;
  OperatorList.Add(op);
  {Evaluation de int }
  New(op);
  op.name:='?>';
  op.leftOp:='*';
  op.Pop:=@eval_printedtext;
  OperatorList.Add(op);

  {Evaluation de isset }
  New(op);
  op.name:='isset';
  op.leftOp:='*';
  op.Pop:=@eval_isset;
  OperatorList.Add(op);
  {Evaluation de isset }
  New(op);
  op.name:='sumFX';
  op.leftOp:='*';
  op.Pop:=@eval_sumFx;
  OperatorList.Add(op);
  {Evaluation de and }
  New(op);
  op.name:='and';
  op.leftOp:='(';
  op.Pop:=@eval_standartBoolOperator;
  OperatorList.Add(op);
  {Evaluation de xor }
  New(op);
  op.name:='xor';
  op.leftOp:='(';
  op.Pop:=@eval_standartBoolOperator;
  OperatorList.Add(op);
  {Evaluation de or }
  New(op);
  op.name:='or';
  op.leftOp:='(';
  op.Pop:=@eval_standartBoolOperator;
  OperatorList.Add(op);



end;



end.
