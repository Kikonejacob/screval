unit script;
{ SCR EVAL: interpretateur de script
 01.01. 2010

26 avril correction generale

attention:note: en cas d'erreurs activer  showmessage('jumpline'); dans scroperate

}
interface

uses eval,windows,sysutils,classes,gutils,common,eval_extra;
{gutils est utilisé uniquement pour xcount_delimiter()}






function pl_add(Item:pointer;list:plist):integer;
function pl_get(index:integer;list:plist):integer;
function pl_delete(index:integer;list:plist):integer;
function pl_mov(index,new_index:integer;list:plist):integer;
function xcount_delimiter(delimiter,str:string):integer;



//function scr_decompose(texte:string;sc:Pinstructions):pinstructions;
function scr_decompose(texte:string;scr:PscrInfo):pinstructions;
function scr_operate(scr:PscrInfo):integer;
function scr_eval(PID:integer;text:string):PscrInfo ;
function scr_evalEx(text:string;scr:PscrInfo;ePID:integer):integer;
function scr_preOperate(scr:PscrInfo):integer;
function Manage_scr_error(EpInfo:PepInfo;scr:PscrInfo):integer;



function msgbox(str:string):integer;
function loadcode(ePID:integer;filename:string;parentNameSpace:string):integer;
function loadcodeEx(filename,parentNameSpace:string;scr:pscrInfo):integer;

function checkFunctionDeclaration(namespace:string;PID:integer):integer;
function EvalScriptFromFile(PID:integer;filepath:string;const parentNameSpace:string=''):PscrInfo; overload;
function EvalScriptFromFile(PID:integer;filepath:string;silenceMode:boolean;const parentNameSpace:string=''):PscrInfo; overload;





implementation
{$DEFINE SCRIPTENABLE;}

function pl_add(Item:pointer;list:plist):integer;

begin
   Result := list.count;
   list.Flist[Result] := Item;
end;
function pl_get(index:integer;list:plist):integer;
begin
end;
function pl_delete(index:integer;list:plist):integer;
begin
end;
function pl_mov(index,new_index:integer;list:plist):integer;
begin
end;


{fonction qui permet d'avoir la fin d'un bloc}
function get_bloc_end(texte:string;SeekStartPos:integer;b_beg,b_end:string):integer;
var
    count_beg,count_end,i:integer;
    str,tmp:string;
begin

   count_beg:=0;count_end:=0;
    str:=copy(texte,SeekStartPos,Length(texte));
    i:=1;
   // msgbox('jhhj');
    while (((count_beg<>count_end) or (count_beg=0)) and (i<=length(str)) )do
    begin
      if (b_beg='{') and (b_end='}') then
      begin
        if (str[i]='"') or (str[i]='''') then
        begin
          i:=i+pos(str[i],copy(str,i+1,length(str)-(i)));
         //showmessage(str[i]);
        end
        else
        if (copy(str,i,2)='?>')   then
        begin
          if pos('<?',copy(str,i+2,length(str)-i))>0 then
          begin
            i:=i+pos('<?',copy(str,i+2,length(str)-i))+2;
          end
          else
          begin
            i:=length(str);
           end;
        end;

      end;
     tmp:=copy(str,i,length(b_beg));
    // msgbox(tmp);
     if (pos(b_beg,tmp)>0) then    inc(count_beg);
     tmp:=copy(str,i,length(b_end));
     if (pos(b_end,tmp)>0) then    inc(count_end);
     If (count_Beg=count_End)and (count_Beg>0)then
     begin
     Result:=i;
     break;
     end;

    inc(i) ;
   // msgbox(str);
    end;
    if result<>-1 then result:=result+SeekStartPos-1;
     // si pBeg=pEnd appliquer la procedure ci-dessous est justifié #crer une routine d'erreur
    If count_beg<>count_end Then
   result:=-1;{Renvoie une erreur}
    //msgbox(copy(str,result,length(str))+inttostr(result));
  
end;

function f_error(i:integer):integer;
begin
  messagebox(0,'gffg','fggfg',0);
end;
function msgbox(str:string):integer;
begin
   messagebox(0,Pchar(str),'fggfg',0);
end;

//fonction qui permet de compter le nombre de repetition de caractère dans une chaine
function count_str(texte,ch:string):integer ;
var
  str:string;count,i:integer;
begin
  str:=texte;i:=pos(ch,str); count:=0;
  while(not(i=0)) do
  begin
    inc(count);
    str:=copy(str,i+1,(length(str)-i));
    i:=pos(ch,str);
  end;
  result:=count;
end;

//Parse le texte en insctructions;
function scr_decompose(texte:string;scr:PscrInfo):pinstructions;
{Determine si les mot clée ne sont pas contenu dans du texte}
function IsnotInText(str:string):boolean;
begin

  if (count_str(str,'"')/2)>0 then
  result:=(count_str(str,'"')/2)=int((count_str(str,'"')/2))
  else
  if (count_str(str,'''')/2)>0 then
  result:=(count_str(str,'''')/2)=int((count_str(str,'''')/2))
  else
  result:=true;
end;
var
  str,tmp:string;
  i,a,lastpos:integer;
  //scr:Pinstructions;
  instruction:pinstruction;
  traited:boolean;
  iscomment:boolean;
  //usingPrintedText:boolean;  {permet de savoir si on utilise les printedtext like <?...?> Obsolete voir TscrInfo.useprintedText}
begin
  str:=texte;lastpos:=1;i:=1; //usingPrintedText:=false;

  if (pos('<?',str)<pos('?>',str)) and (pos('<?',str)>0) then
  begin
    lastpos:=pos('<?',str)+2;
    scr.IncorporetedScript:=true;
    {add a printed test instruction}
    new(instruction);
    instruction.text:=E_STRING(copy(str,0,pos('<?',str)-1));
    instruction.bufsize:=strLen(instruction.text);
    instruction._type:=instruct_printedText;
    instruction.canEval:=false;
    instruction.position:=1;
    instruction.startpos:=1;
    instruction.state:=iuntraited;
    setlength(scr.instructions,length(scr.instructions)+1);
    scr.instructions[high(scr.instructions)]:=instruction;

    str:=copy(str,pos('<?',str)+2,length(str));

    //usingPrintedText:=true;
   // showmessage(str);
    //showmessage('lastpost:'+inttostr(lastpos));
  end;

  //showmessage(str);
  while(i<=length(str)) and (length(str)>0) do
  begin
   //Detection des tokens
   //msgbox(inttostr(i));
   //msgbox(str+inttostr(i));
   traited:=false;

     //Detection des commentaires inline
   if (pos('//',copy(str,i,2))>0)  and  IsnotInText(copy(str,0,i)) then
   begin
   tmp:=copy(str,i,length(str)-i);
     if  (pos(#13#10,tmp)>0)  then    a:=i+pos(#13#10,tmp)   else    a:=length(str);
     //Ici a represente le premier retour a la ligne après // ou la fin du texte
     //showmessage(inttostr(a));
    //showmessage(inttostr((count_str(copy(str,1,i),'"')))+' COMPARE '+inttostr(count_str(copy(str,i,a-i),'"')));

     if (count_str(copy(str,1,i),'"'))=0 then
     iscomment:=true
     else
     iscomment:= not(count_str(copy(str,1,i),'"')=count_str((copy(str,i,a-i)),'"'));
     if iscomment then
     begin
      //msgbox( 'COMMENT:'+copy(str,i,a-i));


       lastpos:=lastpos+a;
       i:=0;
       str:=copy(str,a+1,length(str)-(a));
      // showmessage(str+' '+inttostr(i)+':'+inttostr(length(texte)));
       traited:=true;
     end;


   end
   else
   //Detection des commentaires /*commentaire*/
   if (pos('/*',copy(str,i,2))>0)then
   begin
     iscomment:=false;
     if (count_str(copy(str,1,i),'"'))=0 then
     iscomment:=true
     else
     iscomment:= not(count_str(copy(str,1,i),'"')=count_str((copy(str,i,a-i)),'"'));
     if iscomment  then
     begin
      a:=pos('*/',copy(str,i,length(str)-i)) ;
      //msgbox(str);
      if (a=0)then
      begin
      //f_error()
      exit;
      end;
      str:=copy(str,a+i+1,length(str)-a);
      //showmessage(str);
      lastpos:=lastpos+a;
      i:=0;
      traited:=true;
     end;
   end
   else
   // saute les ";" contenus dans les parenthèses pour compatibilité avec boucle for
   if (str[i]='(') then
   begin
     //showmessage(copy(str,i,length(str)-i));
     //showmessage(inttostr(get_bloc_end(copy(str,i,length(str)-i),'(',')'))+ str[i]);
     //showmessage(copy(str,i, get_bloc_end(copy(str,i,length(str)-i),'(',')')));
     if (get_bloc_end(copy(str,i,length(str)-i+1),1,'(',')')>0) then
     i:=get_bloc_end(copy(str,i,length(str)-i+1),1,'(',')')+i-1;
     //showmessage('hj'+copy(str,i,length(str)-i+1));
     //showmessage(str[i]);

   end
   else
   // cas d'un " ou ' pour le texte
   if (str[i]='"') or (str[i]='''') then
   begin
    i:=i+pos(str[i],copy(str,i+1,length(str)-(i)));
    //showmessage(str[i]);
   end
   else
   if (copy(str,i,2)='?>') and (scr.IncorporetedScript)  then
   begin
     //usingPrintedText:=true;
     a:=i;
      //lastpos:=lastpos-i+pos('<?',copy(str,i+2,length(str)-i))+2;
     // showmessage(copy(str,i+2,length(str)-i));
     if pos('<?',copy(str,i+2,length(str)-i))>0 then
     begin
       i:=i+pos('<?',copy(str,i+2,length(str)-i))+2;
     end
     else
     begin
       i:=length(str);
     end;
     a:=0;
     //lastpos:=lastpos+i;
    // showmessage('i'+inttostr(i));
     //showmessage(copy(str,i+1,length(str)));
    //showmessage(copy(str,i,length(str)));
   end
   else
   //traite les instructions de base
   if(str[i]=';') then
   begin
     //msgbox('hjhj'+inttostr(count_str(copy(str,0,i),'('))+'  '+inttostr(count_str(copy(str,0,i),')')));
     if ((count_str(copy(str,0,i),'('))=(count_str(copy(str,0,i),')'))) or
      ((count_str(copy(str,0,i),'('))>(count_str(copy(str,0,i),')')))   then //si c'est pas dans la string
     begin
      new(instruction);
      // msgbox('hjhj'+copy(str,0,i-1));
      instruction.text:=E_STRING(copy(str,0,i-1));
      instruction.bufsize:=strLen(instruction.text);
      instruction._type:=instruct_token;
      instruction.canEval:=true;
      instruction.position:=lastpos+i;
      instruction.startpos:=lastpos;
      instruction.state:=iuntraited;
      setlength(scr.instructions,length(scr.instructions)+1);
      scr.instructions[high(scr.instructions)]:=instruction;
      str:=copy(str,i+1,length(str)-(i));
     
      //msgbox( scr[high(scr)].text);
      //msgbox(str+' JACOVB');

      lastpos:=lastpos+i;
      //showmessage(inttostr( instruction.startpos));
      i:=0;
      traited:=true;

     end;
   end
     else
   //Detection des blocs
   if(str[i]='{') then
   begin
      traited:=true;
     //msgbox('hhjj');
     //msgbox(copy(str,0,(i-1)));
     if (length(copy(str,0,(i-1)))>0) then
     begin
       new(instruction);
       instruction._type:=instruct_prebloc;
       instruction.text:=E_STRING(copy(str,0,i-1));
       instruction.bufsize:=strlen(instruction.text);
       //showmessage(instruction.text);
       instruction.position:=lastpos+length(instruction.text);
       instruction.startpos:=lastpos;
       instruction.state:=iuntraited;
       setlength(scr.instructions,length(scr.instructions)+1);
       scr.instructions[high(scr.instructions)]:=instruction;
       //msgbox(scr[high(scr) ].text);
     end;

     a:=get_bloc_end(str,i,'{','}');
     //msgbox(str+inttostr(a));
     if (a=-1) then
     begin
     //result:=f_error(1);exit;
       scr.error_id:=E_Parse_ERROR;
       scr.error_msg:=' Unterminated structure."}" attendu mais pas trouvé';
       scr.error_namespace:=scr.Name;
       //scr.error_pos:= lastpos+i;
      // scr.error_line:=1+ xcount_delimiter(#13#10,copy(texte,0,lastpos+length(instruction.text)+i));
       scr.error_pos:=length(texte);
       scr.error_line:=1+xcount_delimiter(#13#10,texte);
       //showmessage('hjh');
       exit;
     end;
     new(instruction);
     instruction._type:=instruct_bloc;
     instruction.text:=E_STRING(copy(str,i+1,(a-i)-1));
     instruction.bufsize:=strlen(instruction.text);
     instruction.startpos:=i+lastpos;
     instruction.state:=iuntraited;
     setlength(scr.instructions,length(scr.instructions)+1);
     scr.instructions[high(scr.instructions)]:=instruction;
     str:=copy(str,a+1,length(str)-(a));
     lastpos:=lastpos+a;
     instruction.position:=lastpos;
     i:=0;
   
     //msgbox(str);
   end
   else
   {pour le texte a placé dans scrinfo.rettext:: SI ERREUR A VERIFIER}
   if (pos('<?',copy(str,i,2))>0) and (scr.IncorporetedScript) then
   begin
     //showmessage(copy(str,pos('<?',copy(str,i,2)),length(str)));
     //usingPrintedText:=true;
     //a:=get_bloc_end(str,'<?','?>');
     a:=get_bloc_end(str,i,'<?','?>');
     if a<>-1 then i:=a;
      //lastpos:=lastpos+i;

   end;


   //incremente
   inc(i);
  end;
  {au cas ou le token est a la fin des instructions et n'est pas terminé par ";"}
  if (traited=false) and (length(str)>0) and (trim(str)<>'')then
  begin
      new(instruction);
      //showmessage('SYSSS__'+str);
      instruction.text:=E_STRING(str);
      instruction.bufsize:=strlen(instruction.text);
      instruction._type:=instruct_token;
      instruction.canEval:=true;
      instruction.position:=lastpos+length(str);
      instruction.startpos:=lastpos;
      instruction.state:=iuntraited;
      setlength(scr.instructions,length(scr.instructions)+1);
      scr.instructions[high(scr.instructions)]:=instruction;
      str:='';


  end;
  if trim(str)<>'' then
  begin
  end;

 // msgbox(inttostr(length(scr)));
  //sc:=scr;
  result:=scr.instructions;
end;

function scr_eval(PID:integer;text:string):PscrInfo ;
var
  scr:PscrInfo;
  index:integer;
  currdir:PvarInfo;
  eProcess:PEvalProcessInfo;
begin
  new(scr);
  scr.cmd:=-1;
  scr.error_id:=-1;
  
  //showmessage('hjhj');
  scr.texte:=text;
//  showmessage(text);

  scr.Name:=Pgchar('.#script#'+inttostr(lastnamespaceid+1));
  scr.scrFileName:=Pgchar('.#script# '+inttostr(lastNameSpaceId+1));
  Scr.scrFilePos:=0;
  if scr.PID=-1 then
  begin
    new(eProcess);
    eProcess.AppHandle:=0;
    eProcess.Locked:=false;
    scr.PID:=CreatEvalProcess(eProcess);
  end; 
 // scr.ParentIndex:=-1;
  inc(lastnamespaceid);
  scr.silenceMode:=false;
  scr._type:=scr_run;
  //scr.childNameSpaces:=nil;
  new(currdir);
  fillrinfo(currdir);
  currdir.name:='CurrDir';
  currdir.CharValue:=E_STRING('.\');
  currdir.rtype:=vt_char;
  currdir.group:=E_STRING(scr.Name);
  setvar(PID,currdir);
  index:=AddNameSpace(PID,scr,scr.name,false);
  scr_decompose(text,scr);
  if scr.error_id<>E_NONE then
  begin
    manage_scr_error(nil,scr);
    exit;
  end;
  
  scr_PreOperate(scr);
  if scr.error_id<>E_none then
  manage_scr_error(nil,scr)
  else
  scr_operate(scr);
  deleteNamespace(scr.PID,scr.Name,true);
  deleteEvalProcess(scr.PID);
  result:=scr;
end;

function scr_evalEx(text:string;scr:PscrInfo;ePID:integer):integer;
begin
   scr.texte:=text;
   
  AddNameSpace(ePID,scr,scr.name,true);
  scr_decompose(text,scr);
  scr_preoperate(scr);
 { if (scr._type=scr_embedded) then
  begin
    showmessage(inttostr(length(scr.instructions)));
  end;   }
  // showmessage('SCR____'+scr.texte);

//  if  (scr.error_id<>E_NONE) and (scr.silenceMode=false) then
if  (scr.error_id<>E_NONE)  then
begin
    //showmessage('kjk');
    manage_scr_Error(nil,scr);
    exit;
end;
  result:=scr_operate(scr);
  if (scr._type=scr_namespace) or (scr._type=scr_class) then
  checkFunctionDeclaration(scr.Name,scr.PID);

end;

{fonction qui donne des information sur l'erreur à l'application hote
portion tirée de DLG_SCR_ERROR
27.04.2011}
function  ShowScrError(EpInfo:PEpInfo;scr:PscrInfo):integer;
var
    msg:string;
    line,scrfilepos:integer;
    ns,source,scrFile:string;
    errScr:PscrInfo;
    nsId:integer;
    flag:integer;{0 si erreur d'évaluation 1 si erreur de parsing}
begin

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
      errScr:=PScrInfo(namespacelist[indexfromNamespace(scr.error_namespace,scr.PID)]);
      scrfilepos:=errScr.scrFilePos;
      //showmessage(inttostr(errscr.error_line));
      //showmessage(errscr.Namespace+ ' namespace  '+errscr.parentNamespace);
      //showmessage('file name: '+errscr.scrFileName);
      msg:=errScr.error_msg;
      //if errscr.scrFileName='#parent#' then   showmessage('file name: '+errscr.scrFileName);
      //showmessage(inttostr(errscr.ParentIndex));
      line:= errScr.error_line; {ligne  uniquement à l'échelle du namespace local}
      if copy(errscr.scrFileName,1,length('#classmethode#'))='#classmethode#' then
      begin
         ns:=copy(errscr.scrFileName,length('#classmethode#')+1,length(errscr.scrFileName));
         showmessage('errorNs:'+ns);
         nsid:=indexFromNameSpace(ns,scr.PID);
        if (nsid<>-1)  then errScr:=PscrInfo(namespacelist[nsid]);
      end;
      while  (errscr.scrFileName='#parent#') do
      begin
        nsid:=indexFromNameSpace(errScr.parent,scr.PID);
        if (nsid=-1)  then break;
        errScr:=PscrInfo(namespacelist[nsid]);

      end;

      source:=errScr.texte;
      line:=line+xcount_delimiter(#13#10,copy(source,0,scrfilepos));
      //showmessage(copy(source,0,scrfilepos));

      scrfile:=errScr.scrFileName;

    end;
    if EPInfo=nil then flag:=1 else flag:=0;

    ShowScrErrDlg(line,pchar(msg),pchar(scrFile),pchar(source),0,flag);



end;

//gestion des erreurs dans le script
function Manage_scr_error(EpInfo:PepInfo;scr:PscrInfo):integer;
var
  str:string; i:integer;
begin
 { for i:=0 to high(scr.instructions) do
  begin
  str:=str+scr.instructions[i].text;
  end;
 }

  // showmessage('jkjkj:'+str);
   if not scr.silenceMode then
   ShowScrError(EpInfo,scr);
end;
// function qui permet de conter les nombres d'apparition d'un mot dans un string }
function xcount_delimiter(delimiter,str:string):integer;
var
  text:string;
  i,ln:integer;

begin
  i:=0 ;{ pour la dernière ligne}
  text:=str;
  while (pos(delimiter,text)>0) do
  begin
    inc(i);
    //showmessage('xcount'+text );
    ln:=length(text)- pos(delimiter,text)+length(delimiter);
    text:=copy(text,pos(delimiter,text)+length(delimiter),ln);

  end;
  //showmessage(str);
  result:=i;
end;

{renvoi l'erreur de lepInfo dans ScrInfo pour la gestion des erreur par le script
ici instructionId= le numero de l'instruction dans le tableau scr.instructions}
function epError_to_scr(epInfo:PepInfo;scr:PscrInfo;instructionId:integer):boolean;
var
  ipos:integer;
begin
      scr.error_id:=epInfo.ErrId;
      ipos:=scr.instructions[instructionId].position ;
      if epinfo.ErrId<>E_none then
      if epInfo.ErrDeclationMode=errAlternative  then {verifie si on a pas utilisé la methode alternative pour déclarer l'erreur}
      begin
        scr.error_id:=Epinfo.ErrId;
        scr.error_pos:=Epinfo.ErrPos+ipos;
        scr.error_msg:=Pgchar(Epinfo.ErrParams);
        scr.error_line:=EpInfo.ErrLn+xcount_delimiter(#13#10,copy(scr.texte,0,ipos));
        scr.error_Namespace:=scr.name;
        {au cas où on demande de faire un calcul normale des lignes a partir de scr.error_pos}
       
        if (EpInfo.ErrLn=-1) then
        begin
        //showmessage(copy(scr.texte,0,scr.error_pos));
        scr.error_line:=1+xcount_delimiter(#13#10,copy(scr.texte,0,scr.error_pos))//-EpInfo.ErrRigthLnCount;
        end;
        //showmessage(scr.error_msg);
      end
      else
      if EpInfo.ErrDeclationMode=errNameSpace then
      begin
        scr.error_NameSpace:=Pgchar(EpInfo.ErrNamespace);
        //showmessage(scr.error_namespace+ '  errornamespace');
        scr.error_id:=Epinfo.ErrId;
      end
      else
      {sinon on applique la regle normale}
      begin
      //showmessage('jkj single');
      //showmessage(scr.texte);
      ipos:=scr.instructions[instructionId].startpos+EpInfo.ErrStrPos-1;
      //showmessage(inttostr(ipos)+':'+inttostr(EpInfo.ErrStrPos));
      scr.error_pos:=ipos;{a revoir pour la précision}
      scr.error_namespace:=scr.Name;
      {on compte le nombre de lignes avant la fin du token et on soustrait le nombre avant la partie de
      de l'erreur}
      //scr.error_line:=1+xcount_delimiter(#13#10,copy(scr.texte,0,ipos))-EpInfo.ErrRigthLnCount;
      scr.error_line:=1+xcount_delimiter(#13#10,copy(scr.texte,1,ipos));
      //showmessage('line:'+inttostr(scr.error_line));
      //showmessage(copy(scr.texte,1,ipos));
      scr.error_msg:=Pgchar(EpInfo.ErrParams);
      end;
      result:=true;
end;

function scr_operate(scr:PscrInfo):integer;
var
  eparr:strarr;
  i:integer;
  rinfo:Prinfo;
  scr2:PscrInfo;
  EpInfo:PepInfo;
  DefEpInfoCmd:integer;
  DefEpInfoCmdArg:pointer;

  errid:integer;
begin
   i:=0;
   errid:=0;
   DefEpInfoCmd:=workNone;{par defaut}
   {cmd manager pour pré evaluation}
   if scr.cmd=SCR_CMD_SWITCH then
   begin
   DefEpInfoCmd:=SCR_CMD_SWITCH;
   DefEpInfoCmdArg:=scr.cmdArg;
      
   end;

   while(not(i>high(scr.instructions))) do
   begin
      scr.index:=i;  //showmessage('instruct____'+ scr.instructions[i].text+'___'+inttostr(integer(scr.instructions[i].state)));
      if scr.instructions[i].state=iuntraited then
      case scr.instructions[i]._type of
      instruct_printedText:
                      begin
                       PrintScreenText(scr.PID,scr.instructions[i].text);
                      end;
      instruct_token: begin
                       new(rinfo);
                       Fillrinfo(rinfo);
                       new(EpInfo);fillEpInfo(EpInfo);
                       epInfo.scr:=scr;
                       //EpInfo.scr.cmd:=-1;
                       ePinfo.y:=-1;
                       epInfo.x:=-1;
                       EpInfo.cmd:=DefEpInfoCmd; EPInfo.cArg3:=DefEpInfoCmdArg;
                       EpInfo.silentMode:=true;
                       EpInfo.group:=E_STRING(scr.Name);
                       EpInfo.PID:=scr.PID;
                       EpInfo.IncorporetedScript:=Scr.IncorporetedScript;
                       EpInfo.groupIndex:=indexFromNameSpace(scr.Name,scr.PID);
                       EpInfo.groupParentIndex:=IndexFromNameSpace(scr.parent,scr.PID);
                       epInfo.defaultMemberAccess:=scr.defaultMemberAccess;
                       //showmessage(scr.instructions[i].text+'____'+inttostr(epinfo.cmd));
                       //showmessage('breakchar:'+epInfobre
                       errid:=scr_evalEp(scr.instructions[i].text,rinfo,false,epInfo,scr);
                       epError_to_scr(epInfo,scr,i);{recoi les erreur survenu lors de l'evaluation}
                       scr.cmd:=EpInfo.scr.cmd;{recoit les cmd pour le script}
                       scr.cmdArg:=EpInfo.scr.cmdArg;
                       freerinfo(rinfo);
                       freeEpInfo(epInfo);
                      end;
      instruct_prebloc:begin
                       new(rinfo);
                       Fillrinfo(rinfo);
                       new(EpInfo);
                       FillEpInfo(EpInfo);
                       epinfo.scr:=scr;
                       EpInfo.scr.cmd:=-1;
                       EpInfo.silentMode:=true;
                       EpInfo.cmd:=DefEpInfoCmd; EPInfo.cArg3:=DefEpInfoCmdArg;
                       EpInfo.group:=E_STRING(scr.Name);
                       EpInfo.PID:=scr.PID;
                       EpInfo.IncorporetedScript:=Scr.IncorporetedScript;
                       EpInfo.groupIndex:=indexFromNameSpace(scr.Name,scr.PID);
                       EpInfo.groupParentIndex:=indexFromNameSpace(scr.parent,scr.PID);
                       epInfo.defaultMemberAccess:=scr.defaultMemberAccess;
                       errid:=scr_evalEp(scr.instructions[i].text,rinfo,false,epInfo,scr);
                       //showmessage(epInfo.ErrParams +' error from prebloc');

                       epError_to_scr(epInfo,scr,i); {recoi les erreur survenu lors de l'evaluation}
                       scr.cmd:=EpInfo.scr.cmd;{recoit les cmd pour le script}
                       scr.cmdArg:=EpInfo.scr.cmdArg;
                       //i:=EpInfo.scr_index;
                       freeEpInfo(epInfo);
                       freerInfo(rinfo);
                       end;
      instruct_bloc: begin
                       new(scr2);
                       //showmessage('MSG:BLOC');
                       scr2.cmd:=-1;
                       scr2.error_id:=-1;
                       scr2.Name:=Pgchar(scr.name+'.'+ GetNewNameSpaceStr);
                       //scr2.childNameSpaces:=nil;
                       scr2.PID:=scr.PID;
                       scr2.IncorporetedScript:=Scr.IncorporetedScript;

                       
                       scr2.silenceMode:=true;
                       //scr2.ParentIndex:=scr.NamespaceId;
                       //showmessage('scr2  '+ inttostr(scr.NamespaceId));
                       scr2.parent:=scr.Name;
                       scr2.scrFileName:='#parent#';
                       scr2.scrFilePos:=scr.instructions[i].startpos+scr.scrFilePos;
                       scr2.defaultMemberAccess:=scr.defaultMemberAccess;
                       //showmessage(copy(scr.texte,0,scr2.scrFilePos)+'  scr');
                       errid:=scr_evalEx(scr.instructions[i].text,scr2,scr.PID);
   
                       scr.cmd:=scr2.cmd;{a revoir: pour que les info d'erreurs aussi soit pris en compte}
                       scr.cmdArg:=scr2.cmdArg;
                       scr.error_id:=scr2.error_id;
                       scr.error_pos:=scr2.error_pos;
                       scr.error_line:=scr2.error_line;
                       scr.error_msg:=scr2.error_msg;

                       {ratachement des erreurs (obsolete pour les déclaration alternative des erreurs}
                       if (scr.Name=scr2.Name) then
                       begin
                       scr.error_pos:=scr2.error_pos+scr.instructions[i].position;  {ajoute la postion de l'instruction geniteur}
                       //showmessage(inttostr(scr.instructions[i].position))
                       scr.error_msg:=scr2.error_msg;
                       scr.error_line:=scr2.error_line+xcount_delimiter(#13#10,copy(scr.texte,0,scr.instructions[i].position));;
                       end;
                       {fin obsolete}
                        scr.error_namespace:=scr2.error_namespace;
                        //showmessage(scr.error_namespace);
                       end;
      end;
      //if (errid>0)    then break;{au cas ou ya erreur}
      {error manager}
      //if (errId=E_NONE) then
      if (scr.error_id<>E_none) then
      begin
      //showmessage('jkj');
      Manage_scr_error(epInfo,scr);
      break;
      end;
      {cmd manager}
      if scr.cmd=work_try_func then
      begin
         scr.cmd:=wait_try_op;
         //showmessage('jkj');
         inc(i);
      end
      else
      if scr.cmd=WORK_CONDITION_TRUE then
      begin
         i:=i+1;
         scr.cmd:=-1;
         DefEpInfoCmd:=WORKED_CONDITION_TRUE;
      end
      else
      if scr.Cmd=WORK_CONDITION_FALSE then
      begin
        i:=i+1;
        scr.cmd:=-1;
        DefEpInfoCmd:=WORKED_CONDITION_FALSE;
      end
      else
      if scr.cmd=wait_try_op then
      begin
         scr.error_id:=E_Try_synthax;
      end
      else
      if scr.cmd=work_try_catch then
      begin
        inc(i);
        scr.cmd:=wait_try_finaly_facultatif;
      end
      else
      if scr.cmd=wait_try_finaly then
      begin
        scr.Cmd:=E_None ;
        scr.error_id:=E_Try_synthax;
      end
      else
      if scr.cmd=work_try_finaly then
      begin
         scr.cmd:=E_None;
         i:=i+1;
      end;
      if (scr.cmd=SCR_CMD_CASE) or (scr.cmd=SCR_CMD_SWITCH) then
      begin
        DefEpInfoCmd:=Scr.cmd;
        DefEpInfoCmdArg:=scr.cmdArg;
      end;
      if (scr.cmd=scr_cmd_jumpline) then
      begin
         {$IFDEF SCR_DEBUG}
         showmessage('jump line');
         {$ENDIF}
         scr.cmd:=E_None;
         if (scr.instructions[i]._type =instruct_prebloc) then
         i:=i+2
         else
         i:=i+1;
      end
      else
      if (scr.cmd=scr_cmd_jump_to) and (EpInfo<>nil) then
      begin
         {$IFDEF SCR_DEBUG}
         showmessage('jump to line'+inttostr(EpInfo.scr.index));
         {$ENDIF}
         i:=EpInfo.scr.index;
         scr.cmd:=E_None;

      end
      else
         inc(i);

      if (scr.cmd=scr_cmd_abort)  then
      begin
      break;
      end;
      if (scr.cmd=scr_cmd_error)   then  {obsolete}
      begin
      f_error(i)
      end;
     
     
 end;
 //showmessage('jkj');

     result:=errId;
end;
{fonction qui permet de charger du script contenu dans un fichier}
function loadcode(ePID:integer;filename:string;parentNameSpace:string):integer;
var
  code:Tstringlist;
  scr:PscrInfo;
  currdir:PvarInfo;
  scrfilepath:string;
  nsid:integer;
begin
   new(currdir);
  fillrinfo(currdir);
  currdir.name:='CurrDir';
  currdir.CharValue:=E_STRING(ExtractFilepath(filename));
  currdir.rtype:=vt_char;
  currdir.group:=E_STRING(scr.Name);
  setvar(ePID,currdir);
  nsid:=IndexfromNameSpace(parentNameSpace,ePID);
  if (extractfilepath(filename)='') and (getvar(ePID,'CurrDir',PscrInfo(namespacelist[nsid]).Name,currdir)=0) then
  scrFilepath:=currdir.CharValue
  else
  scrFilePath:=filename;
  code:=TStringList.Create;
  result:=0;
  try
  code.LoadFromFile(filename);
  except
  result:=-1;
  exit;
  end;

  try
    new(scr);
    scr.cmd:=-1;
    scr.error_id:=-1;
    //scr.ParentIndex:=ParentIndex;
    scr.Name:=Pgchar(parentNameSpace+'.'+ extractFileName(filename));

    scr.scrFileName:=Pgchar(filename);
    Scr.scrFilePos:=0;
 
    showmessage(code.Text+'____load code');

    // scr_EvalEx(code.Text,scr,-1); activer si on veut que le fichier chargé soit utilisé par plusieurs process;
    scr_EvalEx(code.Text,scr,ePID);
  finally
    code.Free;
  end;

end;
{fonction qui permet de charger et d'évaluer du script contenu dans un fichier}
function loadcodeEx(filename,parentNameSpace:string;scr:pscrInfo):integer;
var
  code:Tstringlist;
  currdir:PvarInfo;
  scrfilepath:string;
  parentNsId:integer;
begin

  if scr.Name='' then  scr.Name:=Pgchar(parentNameSpace+'.'+extractFileName(filename));
  ParentNsId:=IndexFromNameSpace(parentNameSpace,scr.PID);

  new(currdir);
  fillrinfo(currdir);
  currdir.name:='CurrDir';
  currdir.CharValue:=E_STRING(ExtractFilepath(filename));
  currdir.rtype:=vt_char;
  currdir.group:=E_STRING(scr.Name);
  setvar(scr.PID,currdir);


  if (extractfilepath(filename)='') and (getvar(scr.PID,'CurrDir',PscrInfo(namespacelist[parentNsId]).Name,currdir)=0) then
  scrFilepath:=currdir.CharValue
  else
  scrFilePath:=filename;
  code:=TStringList.Create;
  result:=0;
  try
  code.LoadFromFile(filename);
  except
  result:=-1;
  exit;
  end;

  scr.cmd:=-1;
  scr.error_id:=-1;
  scr.parent:=Pgchar(parentNamespace);

  //scr.Namespace:=extractFileName(filename);

  scr.scrFileName:=Pgchar(filename);
  Scr.scrFilePos:=0;
  scr.defaultMemberAccess:=apublic;

  //showmessage(code.Text+'____load codeEx');

  //scr_EvalEx(code.Text,scr,-1); {a activer si lon veu pas tenir compte du pid}
  scr_EvalEx(code.Text,scr,scr.PID);
  code.Free;


end;
{permet de savoir si un operateur peut être placé avant un autre operateur donné}
function isOnLeftOp(op,leftoplist:string):boolean;
var
  i:integer;
  str:string;
begin
 i:=pos('*\',leftoplist);
 if leftoplist='*' then
 begin
    result:=true;
    //showmessage(op+ '___val opppppp');
 end
 else
 begin
   if (i>0) then
      str:=copy(leftoplist,i+1,length(leftoplist)-i)
   else
      str:=leftoplist;

   if op=';' then
      result:=pos(';;;;',str)>0
   else
      result:=pos(op,str)>0;
 end;

 if i>0 then
 begin
   result:=result=false;
   
 end;


end;




function pre_prebloc(scr:pscrInfo;i:integer):integer;
var
  a:integer;
  gar:strarr;
  scr2:PscrInfo;
  func:Pfunc;
  argcount:integer;
  argstr:string;
  //lastArgEnd:integer;
  funcDeclaration,HasEnd:boolean;
  str:string;
  EpInfo:PepInfo;
begin

   gar:=EpParse(scr.instructions[i].text,true);
   new(epInfo);
   fillEpInfo(epInfo); epInfo.ErrId:=E_NONE; epinfo.PID:=scr.PID;
   EpInfo.IncorporetedScript:=Scr.IncorporetedScript;

   func:=nil;

          a:=0;
          while(a<=high(gar)) do
          begin
            {
            if (LowerCase(trim(gar[a]))='namespace') then
            begin
              new(scr2);
              scr2.namespace:=GetNewNameSpaceStr;
              scr2.parentNamespace:=scr2.Namespace;
              scr2.heritedNameSpace:=scr2.namespace;
              scr2.texte:=scr.instructions[i+1].text;
              scr.instructions[i]._type:=instruct_passive;
              scr.instructions[i]._type:=instruct_passive;
              scr2._type:=scr_run;
              scr_EvalEx(scr.instructions[i+1].text,scr2);
              scr.error_id:=scr2.error_id;
              scr.error_namespace:=scr2.Namespace;
              addNamespace(scr2,scr.Namespace,scr2.parentNamespace);
              showmessage('namespace declaration');
            end
            else
            
            if gar[a]='class' then
             begin
                new(scr2);
                Fill_scr(scr2);
                scr2.Namespace:=gar[a+1];
                scr2._type:=scr_class;
                scr2.parentNamespace:=scr.Namespace;
                if (a+2<=high(gar)) then

                if gar[a+2]<>'extented' then
                SignalError(EpInfo,a,E_EXTRA,'invalid class declaration')
                else
                scr2.heritedNameSpace:=gar[a+2];

                scr_decompose(scr.instructions[i+1].text,scr2);
                addNamespace(scr2,scr2.Namespace,scr.Namespace);
                scr_preOperate(scr);
                scr.instructions[i]._type:=instruct_passive;
                scr.instructions[i+1]._type:=instruct_passive;
             end
             else }
            if (gar[a]='=') and (LowerCase(trim(gar[a+1]))='function') then
            begin
               {simule la déclaration d'un function pour les hiddenfunc};
               // showmessage('jkjk');
               if (a-2>0) then
               if (gar[a-2]=':') or (gar[a-2]='.') then  {traite les functions déclaré des classes et developpez dans le namespace parent }
               begin
                //showmessage(gar[a+2]);
                 new(func); fillfunc(func);
                 //func.name:=Pgchar(trim(gar[a-1]));
                 //func.groupe:=Pgchar(scr.Name);
                 func.heritedNameSpace:=E_STRING(scr.Name);
                 if (a-3)<0 then
                  begin
                    signalError(EpInfo,a,E_SYNTAX,'function declaration error');
                    break;
                  end;
                  if (gar[a-2]='.') then
                  begin
                    func.groupe:=E_STRING(scr.Name+'.'+gar[a-3]);
                  end
                  else
                  begin
                    func.groupe:=E_STRING(scr.Name+'.'+gar[a-4]);
                    //showmessage(func.name+ '___  ' + func.groupe);
                  end;
                  {autre configurations pour la function}
                  //func.name:=Pgchar('#'+trim(gar[a-1]));
                  strcopy(func.name,Pchar('#'+trim(gar[a-1])));
                  func.params:=E_STRING(FUNC_SIMULATION_PARAMS);
                  func.v_location:=i+1;
                  func.heritedNameSpace:=E_STRING(scr.Name);
                  setfunc(scr.PID,func,func.name,func.groupe);
                  func:=nil;{evite une redéclaration a la fin de la function}
                  
                  //lastArgEnd:=lastArgEnd+2;
               end;
               a:=a+2;
            end
            else
            if (LowerCase(trim(gar[a]))='function')   then
            begin



               //showmessage('function déclaration');
               //lastArgEnd:=a+2;
               str:='';
               new(func);fillfunc(func);

               func.access:=GetScrMembersDefAccess(scr.PID,func.groupe);
               if (a-1>=0) then
               begin
                 if lowercase(gar[a-1])='private' then func.access:=aprivate
                 else
                 if lowercase(gar[a])='public' then func.access:=apublic;
               end;



               //func.name:=Pgchar(trim(gar[a+1]));
               StrCopy(func.name,Pchar(trim(gar[a+1])));
               //showmessage(func.name);
               func.groupe:=E_STRING(scr.Name);
               func.heritedNameSpace:=E_STRING(scr.Name);
               func.v_location:=i+1;{spécifie l'instruction a executé}
               {-------nomage et groupage pour clase et namespace-----}
               if (a+2-high(gar)<0) then
               if (gar[a+2]=':') or (gar[a+2]='.') then  {traite les functions déclaré des classes et developpez dans le namespace parent }
               begin
                //showmessage(gar[a+2]);
                 if high(gar)-(a+3)<0 then
                  begin
                    signalError(EpInfo,a,E_SYNTAX,'function declaration error');
                    break;
                  end;
                  if (gar[a+2]='.') then
                  begin
                    //func.name:=Pgchar('#'+trim(gar[a+3]));
                    StrCopy(func.name,Pchar('#'+trim(gar[a+3])));
                    func.groupe:=E_STRING(scr.Name+'.'+gar[a+1]);
                    inc(a,4);
                  end
                  else
                  begin
                    strcopy(func.name,Pchar('#'+trim(gar[a+4])));
                    func.groupe:=E_STRING(scr.Name+'.'+gar[a+1]);
                    //showmessage(func.name+ '___  ' + func.groupe);
                    inc(a,5);
                  end;
                  {autre configurations pour la function}
                  func.v_location:=i+1;
                  func.heritedNameSpace:=E_STRING(scr.Name);
                  //lastArgEnd:=lastArgEnd+2;
               end
               else
               a:=a+2;
               {-----fin nomage et groupage pour classes et namespaces----}


               //showmessage(scr.Namespace);
               
               (*
               if (a+4)<=high(gar) then {pour les fn° apartenant a des classes}
               if (gar[a+2]=':') and (gar[a+3]=':') then
               begin

               { if getfunc(gar[a+4],gar[a+1],func)<>0 then
                begin
                SignalError(EPInfo,a,E_PERSONAL,format('Declaration of "%s" not found in namespace "%s"',[gar[a+4],gar[a+1]]));
                //  if epInfo.ErrId<>E_NONE then showmessage('impossible de trouver');
                end;
                }
                func.name:=Pgchar('#'+trim(gar[a+4])); {indique que la declaration de la fonction na pas été déclaré}
                func.groupe:=Pgchar(gar[a+1]);
                //showmessage('function_groupe'+func.groupe);
                func.v_location:=i+1;
                func.heritedNameSpace:=Pgchar(scr.Name);
                //lastArgEnd:=lastArgEnd+2;
                a:=a+5;
               end
               else
               a:=a+2;   *)
               funcDeclaration:=true;
               

            end
            else
            {detection des paramètres de la fonction}
            if ((gar[a]=',') or (gar[a]=')') and  (funcDeclaration=true))then
            begin

              if (argstr<>'') then argstr:=argstr+';';
              argstr:=argstr+str;
              str:='';
               if (gar[a]=')') then
               begin
                // showmessage('hjh');
               funcDeclaration:=false;
               func.params:=E_STRING(argstr);HasEnd:=true; break;
               end;

            end
            else
            (*{check the synthax}
            if getoperator(gar[a],op)=0 then
            begin

            end
            else
            if getfunc(gar[a],scr.Namespace,func)=0 then
            begin

            end
            else *)
            begin
            str:=str+gar[a]; // showmessage(inttostr(a)+'jhjh'+inttostr(high(gar))+': '+str );
            end;
            if EpInfo.ErrId<>E_NONE then
            begin
              showmessage(inttostr(i)+ ' error in prebloc');
              EpInfo.silentMode:=true;
              manageerror(EpInfo,gar,nil);
              scr.error_id:=epInfo.ErrId;
              EpError_to_scr(EpInfo,scr,i);
              //showmessage('jkjk');
               exit;
            end;
            inc(a );
         end;

         if (func<>nil) then
         begin
         //showmessage('jhjhj');
         //showmessage(func.name);
         //showmessage(func.params);
         scr.instructions[i]._type:=instruct_passive;
         if func.v_location<>-1 then
         scr.instructions[i+1]._type:=instruct_passive;
         func.ftype:=ft_virtual;

         //showmessage('hhcccj_funcDeclariontEND'+func.name);
         //SetFunc(func,func.name,scr.Name);
         SetFunc(scr.PID,func,func.name,func.groupe);
         func:=nil;
         end;
         SetLength(gar,0);
         freeEpInfo(epInfo);
end;

function pre_token(scr:PscrInfo;i:integer):integer;
var
   a,b:integer;
   lastArgEnd,argcount:integer;
   gar:strarr;
   func,func2:Pfunc;
   op:Poperator;
   //varinfo:PvarInfo;
   str,argstr:string;
   hasEnd,funcDeclaration:boolean;
   pbeg,pend,strc1,strc2:integer;  {strc1=" and strc2='}
   epInfo:PepInfo;arginfo:Tlist;
   previewTraited:TpreviewTraited;
   scr2:PscrInfo;
begin
     pbeg:=0;pend:=0;
     strc1:=0;strc2:=0;
     //new(op);
     //new(varinfo);
     new(epInfo);
     fillEpInfo(EpInfo); epInfo.ErrId:=E_NONE; EpInfo.PID:=scr.PID;
     EpInfo.IncorporetedScript:=Scr.IncorporetedScript;
     funcDeclaration:=false;
     func:=nil;func2:=nil;
     previewTraited:=pt_variable;
     {begin}
     gar:=EpParse(scr.instructions[i].text,true);
     a:=0;
     while(a<=high(gar)) do
     begin
             new(op);new(func2); fillfunc(func2);
               //showmessage('jkj');
             (*if (gar[a]=':') and (a+2<=high(gar))then
             if gar[a+1]=':' then
             begin
                If IndexFromNamespace(gar[a-1])=-1 then
                signalerror(EpInfo,a-1,E_Extra,'Undefined caractère')
                else
                //if (getOperator(gar[a+2],op)<>0) then
                if (getfunc(gar[a+2],gar[a-1],func2)<>0) then
                if getvar( gar[a+2],gar[a-1],varinfo)<>0 then
                signalError(EpInfo,a+2,E_EXTRA,'This caractère is not member  of namespace');
             end
             else *)
             //showmessage(gar[a]);
             if (lowerCase(gar[a])='var') then  {detection des déclarations des variables}
             begin
               a:=high(gar);
             end
             else
             if (lowerCase(gar[a])='function') then  {detection des déclarations des fonctions}
             begin
              // showmessage('jkj_function_token');
               
                if   (scr._type<>scr_class) and (scr._type<>scr_namespace) then
                signalError(EpInfo,a,E_PERSONAL,'Can not declare function outside of a class or namespace');
                {$IFDEF DEBUG_MODE}
                  showmessage('function  semi déclaration');
                {$ENDIF}
                lastArgEnd:=a+2;
                scr.instructions[i]._type:=instruct_passive;
                new(func);fillfunc(func);
                {if getfunc(gar[a+1],scr.Namespace,func)<>0 then
                signalError(EpInfo,a,E_PERSONAL,'function defined but not implemented')
                else
                funcDeclaration:=true ;
                }
                //showmessage(gar[a+1]+'  '+scr.Name);
                if (getfunc(scr.PID,'#'+trim(gar[a+1]),scr.Name,func)=0) then
                begin

                  if (string(func.params)<>FUNC_SIMULATION_PARAMS) then
                  begin
                    strcopy(func.name,Pchar(trim(gar[a+1])));
                    setfunc(scr.PID,func,'#'+trim(gar[a+1]),scr.Name);
                  end
                  else
                    unsetFunc(scr.PID,func.name,func.groupe);
                end
                else
                signalError(EpInfo,a,E_PERSONAL,'function defined but not implemented');
                a:=high(gar);//pour sauter les autres puisque c'est just une définition de token;
            end
            else
            if ((gar[a]=',') or (gar[a]=')') and  (funcDeclaration=true))then
            begin

              if (argstr<>'') then argstr:=argstr+';';
              argstr:=argstr+str;
              str:='';
               if (gar[a]=')') then
               begin

               funcDeclaration:=false;
               func.params:=E_STRING(argstr);HasEnd:=true; break;
               end;

            end
            else
            if scr._type=scr_class then
            begin
             // SignalError(EpInfo,a,E_PERSONAL,'class can receive only attributes or methodes');
             // a:=high(gar);
            end
            else
             if (gar[a]='(') then inc(pbeg)
             else
             if (gar[a]=')') then inc(pend)
             else
             if (gar[a]='"') then inc(strc1)
             else
             if (gar[a]='''') then inc(strc2)
             else
             if (gar[a]=':') and ((a+2)<=high(gar)) and ((a-1)<0) then
             begin
               if (gar[a+1]=':') and (indexfromnamespace(gar[a-1],scr.PID)=-1) then
               signalError(EpInfo,a,E_Personal,'undef "'+gar[a-1]+'"');
               {ajouter aussi au cas ou l'élement du namespace n'est pas connu}

             end;

             if (gar[a]=',') and (pbeg=pend) then {ici on suppose que tout ',' doit se placer dans une parenthèse}
             signalError(Epinfo,a,E_Syntax,'utilisation incorrecte de "," dans ce contexte')
             else
             if gar[a]='?>' then
             a:=a+2
             else
             if (getoperator(gar[a],op)=0) then
             begin
               //showmessage(gar[a]);
              if (previewtraited=pt_operator) and (op.name<>'"') then
              begin
                if  (IsOnLeftOp(gar[a-1],op.leftOp)=false)  then
                begin
                signalError(Epinfo,a,E_Syntax,format('Operator "%s" use error',[gar[a]])) ;
                //showmessage('tttjkjk__  '+gar[a]+gar[a-1]+ op.leftOp)  ;
                end;
              end
              else
              if (((a-1)<0) and (op.leftOp<>'*') and (op.leftOp<>'')) then
              signalError(Epinfo,a,E_Syntax,'operator must be uses with left argument');

              previewtraited:=pt_operator;
             end
             else
             if getfunc(scr.PID,gar[a],scr.Name,func2)=0 then
             {verification du nombre d'arguments}
             begin

               arginfo:=Tlist.Create;
               //argInfo.Clear;
               getArgInfo(scr.PID,func2,arginfo);
               if (a+2<=high(gar)) then
                 if (gar[a+1]='(') then
                 begin
                   if gar[a+2]<>')' then argcount:=1 else argcount:=0;
                   //for b:=0 to getParaEnd(gar,a+1) do if (gar[b]=',') then inc(argcount);
                   {14.juin.2012}
                   b:=a+2;
                   while (b<getParaEnd(gar,a+1)) do
                   begin
                     if gar[b]='(' then b:=getParaEnd(gar,b)
                     else
                     if gar[b]=',' then inc(argcount)
                     else
                     if b=-1 then b:=getParaEnd(gar,a+1);
                     inc(b)
                   end;
                   {fin 14.juin.2012}
                   if argcount<>argInfo.Count then
                   signalError(EpInfo,a,E_NoAllArgs,'');
                 end;
                 previewTraited:=pt_function;
                 argInfo.Free;
             end
             else
             begin

             previewTraited:=pt_variable;
             end; inc(a);
            dispose(op);freefunc(func2);
     end;
         if (pend<>pbeg) then  signalError(Epinfo,a,E_NoParaEnd,'');
         {if ((strc1 mod  2)<>0)  then signalError(EpInfo,a,E_nocharEnd,'');
         if ((strc2 mod 2 )<>0) then signalError(EPinfo,a,E_NoCharEnd,'');
         }
         if ((strc2 mod 2 )<>0) and (strc1=0) then signalError(EPinfo,a-1,E_NoCharEnd,'');
         if ((strc1 mod 2 )<>0) and (strc2=0) then signalError(EPinfo,a-1,E_NoCharEnd,'');



         //freefunc(func);

         

          if EpInfo.ErrId<>E_NONE then
          begin
          //showmessage(inttostr(i)+ 'errorID__'+scr.instructions[i].text);
          EpInfo.silentMode:=true;
          EpInfo.ErrStrPos:=GetEpStrErrPos(scr.instructions[i].text,EpInfo.ErrPos);
          manageerror(EpInfo,gar,nil);
          scr.error_id:=epInfo.ErrId;
          EpError_to_scr(EpInfo,scr,i);
          {$IFDEF DEBUG_MODE}
          showmessage('jkjk____'+ scr.error_msg);
          showMessage(scr.instructions[i].text);
          {$ENDIF}
          exit;
          end;

         if (func<>nil) then
         begin
         //showmessage('jhjhj');
         //showmessage(func.name);
         //showmessage(func.params);
         //scr.instructions[i]._type:=instruct_passive;
         //func.ftype:=ft_virtual;
         //SetFunc(func,func.name,scr.Namespace);
         func:=nil;
         end;
         //showmessage(scr.instructions[i].text);
         //if (scr.instructions[i]._type=instruct_passive) then         showmessage('passive');
     SetLength(gar,0);
     freeEpInfo(epInfo);
end;
{Recherche les déclarations comme les functions}
function scr_preOperate(scr:PscrInfo):integer;
var
   i,a,b:integer;
   lastArgEnd,argcount:integer;
   gar:strarr;
   func,fn:Pfunc;
   op:Poperator;
   varinfo:PvarInfo;
   str,argstr:string;
   hasEnd,funcDeclaration:boolean;
   pbeg,pend,strc1,strc2:integer;
   //epInfo:PepInfo;
   //arginfo:Tlist;
   previewTraited:TpreviewTraited;
   scr2:PscrInfo;
begin
   i:=0;
   str:='';
   func:=nil;
   //new(fn);new(op);new(varinfo);
   //arginfo:=tlist.Create;

   //showmessage(inttostr(high(scr.instructions)));
   while (i<=high(scr.instructions)) do
   begin
     funcDeclaration:=false;
     pbeg:=0;pend:=0;
     strc1:=0;strc2:=0;
     //new(epInfo);   epInfo.ErrId:=E_NONE;
     previewTraited:=pt_variable;
     case scr.instructions[i]._type of
     instruct_token:
         begin
          pre_token(scr,i);
         end;


     instruct_prebloc:
          begin
             pre_prebloc(scr,i);
         end;
     end;
    inc(i);
   end;
     // showmessage('jhjhj');
     //dispose(epinfo);
end;



{fonction qui permet de verifier que toutes les fonctions implémenté ont bien été identifié}
function checkFunctionDeclaration(namespace:string;PID:integer):integer;
var
  i:integer;
  nsId:integer;
begin
  result:=0;
  nsId:=IndexFromNamespace(namespace,PID);
  for i:=0 to funclist.Count-1 do
  if string(Pfunc(funclist[i]).groupe)='#'+namespace then
  begin
    with PscrInfo(namespacelist[nsid])^ do
    begin
       error_Id:=E_Personal;
       error_msg:=Pgchar('function non déclaré dans '+namespace);
       error_namespace:=Pgchar(namespace);
       error_pos:=Pfunc(funclist[i]).v_location;
    end;



  end;

end;

{fonction qui permet d'evaluer du script a partir d'un fichier    [OVERLOAD pour support de SilenceMode]
par defaut vous pouvez affecter '' à parentnamespace
renvoie un pointeur sur le scr du script exécuté sous forme integer}
function EvalScriptFromFile(PID:integer;filepath:string;silenceMode:boolean;const ParentNameSpace:string=''):PscrInfo; overload;
var
     scr:PscrInfo;
begin
     new(scr);
     Fill_scr(scr);
     scr.IncorporetedScript:=true;{TODO: Modifier si on ne veut pas que pas que l'evalaution soit avec support de script incorpore}
     scr.Name:='';{sera automatiquement defini}
     scr.parent:=ParentNamespace;
     scr.PID:=PID;
     scr.silenceMode:=silenceMode;
     if LoadCodeEx(filepath,scr.parent,scr)=-1 then
     msgbox(format('can not load file "%s"',[filepath]));
     result:=scr;
     //deleteNamespace(PID,scr.Name,true);


end;
{fonction qui permet d'evaluer du script a partir d'un fichier
par defaut vous pouvez affecter '' à parentnamespace
renvoie un pointeur sur le scr du script exécuté sous forme integer}
function EvalScriptFromFile(PID:integer;filepath:string;const ParentNameSpace:string=''):PscrInfo;   overload;
begin
  EvalScriptFromFile(PID,filepath,false,ParentNamespace);
end;

end.
