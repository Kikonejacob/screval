unit scr_reg_eval;
{cette unité comporte les différent composants de la 2eme couche(scrEval) qui agissent
avec la 1ere couche( Epeval)

22 avril 2011 amelioration

}
interface
uses eval,script,classes,common,sysutils,gutils,regeval,eval_extra;
function reg_scr_op():integer;


implementation
//Evalue l'opérateur logique de negation  !
function Eval_negation(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  dresult:prinfo;s_inf:Pepinfo;
begin

  New(s_inf);New(dresult);
  fillEpInfo(s_inf);
  EpInfoCopy(s_inf,EpInfo);//s_inf^:=Epinfo^;
  Epinfo.cmd:=worknone;

  
  //showmessage('hjhjj');
  //dresult.IntValue:=0;
  FillrInfo(dresult);
  if (Eparr[EpInfo.x+1]='=')   then      // exemple "!= "
  begin
     s_inf.x:=s_inf.x+2;
     s_inf.y:=s_inf.x;
    if (operateint(s_inf,Eparr,dresult)=0) then
    begin
        if CheckCompatible(rinfo,dresult,rinfo.rtype) then
        begin
        case (rinfo.rtype)  of
          vt_integer:
                  begin
                  rinfo.BoolValue:=not(rinfo.IntValue= dresult.IntValue);
                  //showmessage(inttostr(rinfo.intvalue)+' '+ inttostr(dresult.intvalue)+Eparr[s_inf.x-1]) ;
                  //if rinfo.boolvalue=true then showmessage('TRUE');
                  end;
          vt_bool:
                  begin
                  rinfo.BoolValue:=not(rInfo.BoolValue= dresult.BoolValue);
                  end;
          vt_float:
                  begin
                  rinfo.BoolValue:=not(rinfo.floatvalue= dresult.floatvalue);
                  end;
          vt_char:
                  begin
                  rinfo.BoolValue:=not( StrComp(rinfo.CharValue,dresult.CharValue)=0);
                  showmessage(rinfo.charvalue+'___'+dresult.charvalue);
                  end;
        end;
        rInfo.rtype:=vt_bool;
        end;
    end
    else
    rinfo.ErrId:=dresult.ErrId;
  end
  else
  begin   // exemple (!true)
     inc(s_inf.x);
     s_inf.y:=s_inf.x;
     operateint(s_inf,Eparr,dresult);
     rInfo.rtype:=vt_bool;
      if CheckCompatible(rinfo,dresult,vt_bool) then
      begin
        rinfo.BoolValue:=not(dresult.BoolValue);
      end;

  end;

  EpInfo.x:=s_inf.x-1;
  freerInfo(dresult);
  freeEpInfo(s_inf);
end;

//Evalue les conditions
function Eval_conditionElse(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
    if (EpInfo.cmd=WORKED_CONDITION_TRUE) then
    begin
       EpInfo.cmd:=workabort ;  epInfo.cmd:=workabort ;
       if (EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc )  then
       epinfo.scr.cmd:=scr_cmd_jumpline;
    end
    else
    if (EpInfo.cmd<>WORKED_CONDITION_FALSE) then
    begin
       SignalError(EpInfo,EpInfo.x,E_OPERROR,'condition if attendu');
    end;


end;

//Evalue les conditions
function Eval_condition(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   dresult:prinfo;  s_info:PepInfo;
   scr:PscrInfo;
begin
    New(s_info);
    fillEpInfo(s_info);
    EpInfoCopy(s_info,EpInfo); //s_info^:=EpInfo^;
    inc(s_info.x);
    s_info.y:=GetParaEnd(Eparr,EpInfo.x+1)-1;
    New(dresult);Fillrinfo(dresult);
    // showmessage( Eparr[s_info.y]);
  // showmessage( inttostr(s_info.y));
    Operateint(s_info,Eparr,dresult);
    if (S_info.ErrId<>E_NONE) then
    begin
     SignalError(EpInfo,s_info.ErrPos,s_info.ErrId,s_info.ErrParams);
     //showmessage(epinfo.ErrParams);
     exit;
    end;
    if (not(dresult.BoolValue=true)) then
    begin
       s_info.cmd:=workabort ;  epInfo.cmd:=workabort ;
       //showmessage('no if condition');
       if (s_info.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc )  then
       begin
         epinfo.scr.cmd:=scr_cmd_jumpline;
         EPinfo.scr.cmd:=WORK_CONDITION_FALSE;
       end
       else
          EPinfo.scr.cmd:=WORKED_CONDITION_FALSE;

    end
    else
    if (epInfo.scr.instructions[epInfo.scr.index]._type=instruct_prebloc) then
    begin
        new(scr);
        fill_scr(scr,epinfo.group,EpInfo.PID);
        scr.IncorporetedScript:=EpInfo.IncorporetedScript;
        setlength(scr.instructions,0);
        scr.silenceMode:=true;
        scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,epinfo.PID); {a revoir:revu le 9 mai 2010}
        {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
        if (scr.error_id<>e_None) then
        begin
           EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
           EpInfo.ErrId:=scr.error_id ;
           EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
           EpInfo.ErrParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
           EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
        end;
        if (scr.cmd=scr_cmd_abort) then
           EpInfo.scr.cmd:=scr.cmd
        else
           EPinfo.scr.cmd:=WORK_CONDITION_TRUE;
        deletenamespace(epInfo.PID,scr.Name,true);
    end
    else
    begin
        EPinfo.scr.cmd:=WORKED_CONDITION_TRUE;
        epInfo.cmd:=s_info.cmd;
    end;

    epInfo.x:=s_info.x-1;
    //showmessage(eparr[s_info.x]);
    //showmessage(inttostr(s_info.cmd));

    //signalerror(epInfo,s_info.ErrPos,s_Info.ErrId,s_info.ErrParams);{ au cas ou ya erreur}
    //showmessage(inttostr(epInfo.x)+' if  '+eparr[epInfo.x]);
    //showmessage(inttostr(epInfo.y)+' if y '+eparr[epInfo.y]);
    freeEpInfo(s_info);
    freeRinfo(dresult);
end;
//traite les variables(obsolete)  cette fonction est assurée par evalval dans eval.pas
function traiter_var(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   varInfo:PvarInfo;
   AlternativeVarDec:boolean; {lorque qu'on utilise "var"}
   access:TEvalAccess;
begin
    if varlist=nil then varlist:=Tlist.Create;
    new(varInfo);
    access:=apublic;
    if (rinfo.isReference) and (rinfo.reference='public') then
    access:=apublic;
    if (rinfo.isReference) and (rinfo.reference='private') then
    access:=aprivate;


    AlternativeVarDec:=Eparr[EpInfo.x]='var';
    if AlternativeVarDec then
    begin
      {si le caractère suivant est un namespace}
      if (Eparr[EpInfo.x+1]='$') then     Epinfo.x:=EpInfo.x+1;
    end;

    if  (Eparr[EpInfo.x]='$') or AlternativeVarDec  then
    begin
     if (high(Eparr)<(EpInfo.x+2)) and (AlternativeVarDec) then
      begin
        strcopy(varInfo.name,Pevchar(Eparr[EpInfo.x+1])) ;
        FillrInfo(varInfo);
        varInfo.rtype:=vt_none;
        varinfo.group:=E_STRING(EpInfo.group);
        //showmessage(varinfo.group);
        varinfo.heritedNameSpace:=E_STRING(EpInfo.group);
        varinfo.access:=access;
        varlist.Add(varInfo);
        EpInfo.x:=EpInfo.x+1;
      end
      else
      if (Eparr[EpInfo.x+2]=':') then
      begin

        strcopy(varInfo.name,Pevchar(Eparr[EpInfo.x+1])) ;
        FillrInfo(varInfo);
        varInfo.rtype:=StrTortype(Eparr[ EpInfo.x+3]);
        varinfo.group:=E_STRING(EpInfo.group);
        varinfo.heritedNameSpace:=E_STRING(EpInfo.group);
        varinfo.access:=access;
        varlist.Add(varInfo);
        EpInfo.x:=EpInfo.x+3;
        //showmessage(varInfo.name);
      end
      else
      if   ((Eparr[EpInfo.x+2]='=') and (getVar(EPInfo.PID,Eparr[EpInfo.x+1],EpInfo.group,varInfo)<>0)) then
      {au cas ou on a par exemple $a=5. on déclare la variable automatiquement avant que EqualOp ne comment son traitement}
      begin
        strcopy(varInfo.name,pevchar(Eparr[EpInfo.x+1])) ;
        FillrInfo(varInfo);
        //showmessage('fgfg');
        varInfo.rtype:=vt_none;
        varInfo.group:=E_STRING(epinfo.group);
        varinfo.heritedNameSpace:=E_STRING(EpInfo.group);
        varinfo.access:=access;
        varlist.Add(varInfo);
      
        //rinfo.rtype:=vt_none;
        EpInfo.x:=EpInfo.x+1;
      end
      else
      begin
        getVar(EpInfo.PID,Eparr[EpInfo.x+1],EpInfo.group,varInfo);
        rInfo^:=varInfo^;
        EpInfo.x:=EpInfo.x+1;
      end;
    end;

end;
{evalue l'operateur exit ou abort}
 function eval_abort(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
 begin
    EpInfo.cmd:=workAbort;
    if Assigned(EpInfo.scr) then Epinfo.scr.cmd:=scr_cmd_abort;
 end;

{Evalue un break;   }
function eval_break(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  {pour la structure de choix switch}
   if EpInfo.cmd=work_CASE then
   begin
     EpInfo.cmd:=WORk_SWITCH;
     EpInfo.scr.cmd:=SCR_CMD_SWITCH;
   end
   else
   if EpInfo.cmd=WORK_SWITCH then
   signalError(EPInfo,EpInfo.x,E_UNAPPROPRIETED_USEOFBREAK,'')
   else
   begin
   {pour les boucles}
   EpInfo.scr.cmd:=work_BOUCLE_END; {cas d'un bloc}
   EpInfo.cmd:=work_BOUCLE_END;{ cas d'un token}
   //showmessage('eval break');
   end;
   //showmessage('use of break');
end;
{donne les par défaut d'un PscrInfo}

{Evalue la boucle for
si erreur voir allowJumpingLine de eval_while}
function eval_for(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
 
var
 i:integer;
 arg_count:integer;
 para_end:integer;
 arg_pos:array[0..2]of integer;
 var_str:string;
 dresult,testresult:Prinfo;
 s_inf:PepInfo;
 scr:PscrInfo;

 next_boucle,subBoucleDetected:boolean;{Lorque qu'il ya une boucle suivante dans un prébloc}

begin
 dresult:=nil;
 testresult:=nil;
 para_end:=GetParaEnd(Eparr,EpInfo.x+1);

 if (para_end=-1) then  {Quand ya de blem avec la parenthèse  syntaxe normale:while(x)instruction;}
 begin
 SignalError(EpInfo,EpInfo.x+1,E_PARA_WANTED,format(_ers(E_PARA_WANTED),[Eparr[EpInfo.x+1]]));
 exit;
 end;
 //showmessage(Eparr[high(eparr)]+'  hgh '+inttostr(high(eparr)));
 //showmessage(eparr[6]);
 //  showmessage('MPFOR'+Eparr[para_end]);

 arg_count:=0;
 for i:=(EpInfo.x+1) to para_end do
 if (Eparr[i]=';') then
 begin
    inc(arg_count);
    arg_pos[arg_count-1]:=i;
    //showmessage('ARG:'+Eparr[i]);
 end;

 {Erreur nombre d'arguments incorrect}
 if not(arg_count=2) then
 begin
 SignalError(EpInfo,EpInfo.x,E_FOR_ARGCOUNT,_ers(E_FOR_ARGCOUNT));
 //showmessage('jhj');
 exit;
 end;
 {Initialisation}
 new(s_inf);
 fillEpInfo(s_inf);
 new(scr);
// fill_scr(scr);
 fill_scr(scr,epInfo.group,EpInfo.PID);
 scr.IncorporetedScript:=EpInfo.IncorporetedScript;
 epInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
 s_inf.x:=s_inf.x+3;
 s_inf.y:=arg_pos[0]-1;
// showmessage('begin init'+Eparr[s_inf.x]+'  '+inttostr(s_inf.x));
 //showmessage('FIN  init'+Eparr[s_inf.y]+'  '+inttostr(s_inf.y));
 {initialize iteration}
 new(dresult);
 FillrInfo(dresult);
 Operateint(s_inf,Eparr,dresult);
 freeRinfo(dresult);
 copyEpError(s_inf,epinfo);
 EpInfo.x:= s_inf.y+1;
 if EpInfo.ErrId<>E_none then exit;
 {test}
 EpInfoCOpy(s_inf,EpInfo);//s_inf^:=EpInfo^;
 s_inf.x:=arg_pos[0]+1;
 

 s_inf.y:=arg_pos[1]-1;
 //showmessage('FIN test '+Eparr[s_inf.y]);
 New(testResult);
 FillrInfo(testResult);
 Operateint(s_inf,Eparr,testResult);
 copyEpError(s_inf,epinfo);
 if EpInfo.ErrId<>E_none then exit;
 SubBoucleDetected:=false;


 while   ( (testResult.rtype=vt_bool)  and(testResult.BoolValue=true)) do
 begin
    case (epInfo.scr.instructions[epInfo.scr.index]._type )of
    instruct_token:
                 begin
                  EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
                  s_inf.x:=para_end+1;
                  s_inf.y:=EpInfo.y;
                  //showmessage(Eparr[s_inf.x]+' '+inttostr(EpInfo.y)+ ' '+Eparr[s_inf.y]);
                  new(dresult);
                  FillrInfo(dresult);
                  Operateint(s_inf,Eparr,dresult);
                  signalerror(epInfo,s_inf.ErrPos,s_Inf.ErrId,s_inf.ErrParams);{ au cas ou ya erreur}

                 end;
    instruct_bloc:
                 begin
                 end;
    instruct_prebloc:
                 begin
                 {detection de nouvelle boucle for dans le prébloc}
                 //showmessage('prebloc for');
                 next_boucle:=false;
                // for i:=para_end to EpInfo.y do showmessage(LowerCase(Eparr[i])+ ':for');
                 {verifie si ya pa une autre boucle}
                 for i:=para_end to EpInfo.y do
                 if ('for' = LowerCase(trim(Eparr[i])) )then
                   begin
                   next_boucle:=true;
                   //showmessage('hjh');
                   //showmessage(LowerCase(Eparr[i])+ ':for');
                   break;
                 end;
                 {traite la boucle}
                 if next_boucle then
                 begin
                     SubBoucleDetected:=true;
                     {$IFDEF DEBUG} showmessage('jkj next boucle'); {$ENDIF}
                     EpInfoCOpy(s_inf,EpInfo);//s_inf^:=EpInfo^;
                     s_inf.x:=para_end+1;
                     s_inf.y:=EpInfo.y;
                     new(dresult);
                     FillrInfo(dresult);
                     s_inf.silentMode:=true;
                     Operateint(s_inf,Eparr,dresult);
                     EpInfo.ErrDeclationMode:=s_inf.ErrDeclationMode; {au cas ou on utilise a methode alternative pour déclarer les erreurs}
                     signalerror(epInfo,s_inf.ErrPos,s_Inf.ErrId,s_inf.ErrParams);{ au cas ou ya erreur}
                     EpInfo.ErrLn:=s_inf.ErrLn;{ajoute la ligne au cas d'une déclation alternative d'erreur}
                 end
                 else
                 begin

                    scr.silenceMode:=true;
                    scr.parent:=Epinfo.group;
                    scr.IncorporetedScript:=EpInfo.IncorporetedScript;
                    scr._type:=scr_embedded;
                    Setlength(scr.instructions,0);
                    scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,epInfo.PID); {a revoir: revu e O2.avril 2010}
                    //showmessage('hjhj');
                    //EpInfo.scr_cmd:=scr_cmd_jumpline;
                    {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
                    if (scr.error_id<>e_None) then
                    begin
                     //showmessage(scr.error_msg+' error');

                      EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=scr.error_id ;
                      EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      //showmessage(inttostr(scr.instructions[i].position))
                      //showmessage(inttostr(Epinfo.errPos));
                      EpInfo.ErrParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
                      //showmessage(epInfo.ErrParams+' error test');
                      EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
                     end;
                    

                 end;
                 epInfo.scr.cmd:=scr_cmd_jumpline;
                 end;
   end;
   {gestion des erreurs}
   if epInfo.ErrId<>E_none then
   begin
     //showmessage('erreur dans boucle for');
     exit;
   end;
   {Au cas ou on utilise break}
   If ((s_inf.cmd=work_BOUCLE_END) or (scr.cmd=work_BOUCLE_END)) then
   begin {$IFDEF DEBGUG} showmessage('jkjjk_BREAKFOR'); {$ENDIF} break ;                 end;

   {instruction qui permet de maintenir la bloucle:AGR3: for(?;?,X}
   EpInfoCOpy(s_inf,EpInfo);//s_inf^:=EpInfo^;
   s_inf.x:=arg_pos[1]+1;
   s_inf.y:=para_end-1;
   //showmessage('inst'+inttostr(s_inf.y));
   //showmessage('FIN instruction '+Eparr[s_inf.y]);
   //showmessage(eparr[s_inf.y-1]+'____'+eparr[s_inf.y]);
   new(dresult);
   FillrInfo(dresult);
   Operateint(s_inf,Eparr,dresult);
   freerinfo(dresult);
   //showmessage(inttostr(dresult.IntValue));

  {test si les conditions de la bloucle sont tjr rempli: arg2: for(?;x,?)}
   EpInfoCOpy(s_inf,EpInfo);//s_inf^:=EpInfo^;
   s_inf.cmd:=worknone;
   s_inf.x:=arg_pos[0]+1;
   s_inf.y:=arg_pos[1]-1;
   //showmessage(eparr[s_inf.x]+'____'+eparr[s_inf.y]);
   freeRinfo(testResult);
   new(testResult);
   FillrInfo(testresult);
   Operateint(s_inf,Eparr,testresult);


 end;
 deleteNamespace(EpInfo.PID,scr.Name,true);
 if Assigned(s_inf) then freeEpInfo(s_inf);
 if Assigned(testresult) then freerInfo(testresult);

 EpInfo.x:=EpInfo.y;
end;

function eval_whileExtend(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
begin
  if epInfo.cmd=work_REPEAT_WHILE_CONDITION then
  begin
    EpInfo.x:=EpInfo.x+1;
    operateint(EpInfo,Eparr,rinfo);
    epInfo.cmd:=work_REPEAT_BREAK;{par defaut}
    if EpInfo.ErrId=E_none then
    begin

       if (rinfo.rtype<>vt_bool)  then
       begin
       Signalerror(epinfo,Epinfo.ErrPos,E_REPEAT_WHILE_SYNTHAX,'');
       exit;
       end;
       if (rinfo.rtype=vt_bool) and (rinfo.BoolValue=true)  then
       begin
       EpInfo.cmd:=work_REPEAT_CONTINUE  ;
       //showmessage('can continue');
       end
       else
      EpInfo.cmd:=work_REPEAT_BREAK;
    end;
  end;
end;


{Evalue la boucle  while: difference avec for ne gere pas les insctuction de modification de valeur}
function eval_while(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
 i:integer;
 arg_count:integer;
 para_end:integer;
 arg_pos:array[0..2]of integer;
 var_str:string;
 dresult,TestResult:Prinfo;
 s_inf:PepInfo;
 next_boucle:boolean;{Lorque qu'il ya une boucle suivante dans un prébloc}
 //scr_index_inc:integer;{indique la nouvelle position de scr_index}
 scr:PscrInfo;
 allowJumpingLine:boolean;  //utile pour un prebloc
begin
 {test voir si on appelle pas while pour la condition de "do...while...."  }
 if EpInfo.cmd=work_REPEAT_WHILE_CONDITION then
 begin
 eval_whileExtend(EpInfo,Eparr,rinfo);
 exit;
 end;
 {fin test pour while de "do...while..."}
 para_end:=GetParaEnd(Eparr,EpInfo.x);
 arg_count:=0;
 {Colone suivante es inesistante }
 if (EpInfo.x+1)>High(Eparr) then
 begin
 SignalError(EpInfo,EpInfo.x+1,E_Syntax,'');
 exit;
 end;
 if (para_end=-1) then  {Quand ya de blem avec la parenthèse  syntaxe normale:while(x)instruction;}
 begin
 SignalError(EpInfo,EpInfo.x+1,E_PARA_WANTED,format(_ers(E_PARA_WANTED),[Eparr[EpInfo.x+1]]));
 exit;
 end;



 {Initialisation}
 new(s_inf);
 FillEpInfo(s_inf);
 EpInfocopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
 s_inf.x:=s_inf.x+1;
 s_inf.y:=para_end;
 //showmessage('begin init '+Eparr[s_inf.x]+'  '+inttostr(s_inf.x));
 //showmessage('FIN  init '+Eparr[s_inf.y]+'  '+inttostr(s_inf.y));
 
 {test while(x)}
 new(TestResult);
 FillrInfo(TestResult);
 Operateint(s_inf,Eparr,TestResult);

// scr_index_inc:=0;


 allowJumpingLine:=(epInfo.scr.instructions[epInfo.scr.index]._type=instruct_prebloc); {saute une ligne que soit si a boucle while a pu s'executer ou non}


 while   ( (TestResult.rtype=vt_bool)  and(TestResult.BoolValue=true)) do
 begin
    case (epInfo.scr.instructions[epInfo.scr.index]._type )of
    instruct_token:
                 begin
                  //s_inf^:=EpInfo^;
                  EpInfoCopy(s_inf,EpInfo);
                  s_inf.x:=para_end+1;
                  s_inf.y:=EpInfo.y;
                  //showmessage(Eparr[s_inf.y]);
                  new(dresult);
                  FillrInfo(dresult);
                  Operateint(s_inf,Eparr,dresult);
                  signalerror(epInfo,s_inf.ErrPos,s_Inf.ErrId,s_inf.ErrParams);{ au cas ou ya erreur}
                  freerinfo(dresult);

                 end;
    instruct_bloc:
                 begin
                 end;
    instruct_prebloc:
                 begin
                 {detection de nouvelle boucle while dans le prébloc}
                 //showmessage('prebloc while');
                 next_boucle:=false;
                 for i:=para_end to EpInfo.y do
                 if (LowerCase(Eparr[i])='while' )then
                 begin
                  next_boucle:=true;
                  break;
                 end;
                 {traite la nouvelle boucle interne}
                 if next_boucle then
                 begin
                     EpInfoCOpy(s_inf,EpInfo);//s_inf^:=EpInfo^;
                     s_inf.x:=para_end+1;
                     s_inf.y:=EpInfo.y;
                     new(dresult);
                     FillrInfo(dresult);
                     Operateint(s_inf,Eparr,dresult);
                     EpInfo.ErrDeclationMode:=s_inf.ErrDeclationMode; {au cas ou on utilise a methode alternative pour déclarer les erreurs}
                     signalerror(epInfo,s_inf.ErrPos,s_Inf.ErrId,s_inf.ErrParams);{ au cas ou ya erreur}
                     EpInfo.ErrLn:=s_inf.ErrLn;{ajoute la ligne au cas d'une déclation alternative d'erreur}
                     Freerinfo(dresult);
                 end
                 else
                 begin
                    new(scr);
                    //fill_scr(scr);
                    fill_scr(scr,epinfo.group,EpInfo.PID);
                    scr.IncorporetedScript:=EpInfo.IncorporetedScript;
                    setlength(scr.instructions,0);
                    scr.silenceMode:=true;
                    scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,epinfo.PID); {a revoir:revu le 9 mai 2010}
                    //scr_index_inc:=1
                    //EpInfo.scr_cmd:=scr_cmd_jumpline;
                    {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
                    if (scr.error_id<>e_None) then
                    begin
                     //showmessage(scr.error_msg+' error');

                      EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=scr.error_id ;
                      EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      //showmessage(inttostr(scr.instructions[i].position))
                      //showmessage(inttostr(Epinfo.errPos));
                      EpInfo.ErrParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
                      //showmessage(epInfo.ErrParams+' error test');
                      EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
                    end;
                    deletenamespace(epInfo.PID,scr.Name,true);
                 end;
                 //EpInfo.scr.cmd:=scr_cmd_jumpline; plus besoin de sa car remplacé par AllowJumpingLine
                 end;
   end;

   {gestion des erreurs}
   if epInfo.ErrId<>E_none then
   begin
     //showmessage('erreur dans boucle for');
     freeEpInfo(s_inf);
     freerinfo(testResult);
     exit;
   end;
   {Au cas ou on utilise break}
   If ((s_inf.cmd=work_BOUCLE_END) or (scr.cmd=work_BOUCLE_END)) then
   begin showmessage('jkjjk_BREAKWHILE');  break ;                 end;

  {test si la condition de la boucle est toujours verifiée}
   EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
   s_inf.x:=EpInfo.x+1;
   s_inf.y:=para_end-1;
   freeRinfo(testResult);
   new(testResult);
   FillrInfo(testResult);
   Operateint(s_inf,Eparr,testresult);



 end;
 if AllowJumpingLine then EpInfo.scr.cmd:=scr_cmd_jumpline;  {programme un saut automatique si le while est dans un prebloc}

 EpInfo.x:=EpInfo.y; {saute les instructions suivantes}

 //EpInfo.scr_index:=EpInfo.scr_index+scr_index_inc;
 freeEpInfo(s_inf);
 freerinfo(testResult);
end;



// 10 avril 2010: evalue la structure de choix switch
function eval_switch(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   dresult:Prinfo;
   s_info:PepInfo;
   scr:PscrInfo;
begin

   new(s_info);
   fillEpinfo(s_info);
   new(scr);
   EpInfoCopy(s_info,Epinfo);//s_info^:=EpInfo^;
   S_info.x:=S_info.x+1;
   new(dresult);
   fillrinfo(dresult);
  // showmessage(eparr[s_info.x]);
   {application du modele "switch:..."}

   (*application du modele switch {...} *)
   Operateint(s_info,Eparr,dresult);
   if (dresult.rtype=vt_bool) or (dresult.rtype=vt_char) or (dresult.rtype=vt_integer) or
      (dresult.rtype=vt_float) or (dresult.rtype=vt_numeric) then
   begin
     if (not(EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc)) then
     begin
     signalError(EpInfo,s_info.x,E_SWITCH_SYNTHAX,'');{indique qu'il ya une erreur dans la synthax}
     end;
     new(scr);
     fill_scr(scr,epInfo.group,EPInfo.PID);
     scr.silenceMode:=true;
     scr.cmd:=SCR_CMD_SWITCH;
     scr.cmdArg:=dresult;
     scr.IncorporetedScript:=EpInfo.IncorporetedScript;
     scr_EvalEx(Epinfo.scr.instructions[EpInfo.scr.index+1].text,scr,epinfo.PID);

     if (epInfo.scr.cmd=scr_cmd_abort) then  EpInfo.scr.cmd:=scr_cmd_abort else epInfo.scr.cmd:=scr_cmd_jumpline;

                    {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
                    if (scr.error_id<>e_None) then
                    begin
                     //showmessage(scr.error_msg+' error');

                      EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=scr.error_id ;
                      EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      //showmessage(inttostr(scr.instructions[i].position))
                      //showmessage(inttostr(Epinfo.errPos));
                      strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
                      //showmessage(epInfo.ErrParams+' error test');
                      //showmessage(inttostr(scr.error_line));
                      EpInfo.ErrLn:=scr.error_line;
                    end
                    else
                    deletenamespace(EPInfo.PID,scr.Name,true);

     epInfo.x:=Epinfo.y;
     
   end
   else
   signalError(EpInfo,EpInfo.x+1,E_SWITHC_ARG_TYPE,'');    {indique que la variable conditionné n'est pas de type attendu}
   freeEpInfo(s_info);
   freeRinfo(dresult);
end;
// Evalue le mot clé case dans switch
function eval_case(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   dresult:Prinfo;
   s_info:PepInfo;
   scr:PscrInfo;
function compare_rinfo(rinfo:Prinfo;switchresult:Prinfo):boolean;
begin
  case switchresult.rtype of
  vt_char:
          result:=StrComp(rinfo.CharValue,dresult.CharValue)=0;
  vt_bool:
          result:=(switchresult.BoolValue=rInfo.BoolValue);
  vt_float,vt_date:
           result:=(switchresult.floatvalue=rInfo.floatvalue) ;
  vt_integer:
           result:=(switchresult.IntValue=rInfo.IntValue);
  vt_none:
           result:=(switchresult.rtype=rInfo.rtype);

  end;
end;
begin
   new(s_info);
   new(dresult);
   fillEpInfo(s_info);
   fillrinfo(dresult);
   EpInfoCopy(s_info,EpInfo);
   //s_info^:=EpInfo^;
   s_info.cmd:=workUntil;
   s_info.cArg1:=':';
   s_info.x:=s_info.x+1;
   operateint(s_info,Eparr,dresult);
   if not (EpInfo.cmd=work_SWITCH) then
   begin
      signalError(EpInfo,EpInfo.x,E_CASE_SYNTHAX,''); {au ou on appel case sans switch}
      //if epinfo.cmd=work_case then showmessage('jhjh');
   end;
   if (dresult.rtype=prinfo(Epinfo.cArg3).rtype) and (compare_rinfo(dresult,Prinfo(EpInfo.cArg3))) then
   begin
    EpInfo.cmd:=work_CASE;
    EpInfo.scr.cmd:=scr_cmd_CASE;
    EpInfo.x:=s_info.x;
    //showmessage(Eparr[epinfo.x]);
   end
   else
   if (not (dresult.rtype=Prinfo(Epinfo.cArg3).rtype) ) then
   signalError(EpInfo,EpInfo.x+1,E_CASE_TYPE_INVALID,'');  {erreur car swith arg et case arg ne sont pas de meme type}
   freeEpinfo(s_info);
   freeRinfo(dresult);
end;

{fonction qui permet d'évaluter l'operateur do..while}
function eval_do(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  s_inf:PEpInfo;
  dresult:prinfo;
  scr:PscrInfo;
(*//EVALEP pour l'évaluateur de script de façon simplifié (obsolete) voir scrEvalEp dans eval.pas
function _EvalExpression(Epstr:string;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo):integer;
var
  gar,gar2:strarr;
  str:string;
  i:integer;
begin

  gar:=EpParse(Epstr,true);

  EpInfo.ForUser:=ForUser;
  EpInfo.ListRootStr:='';
  EpInfo.ErrId:=E_none;
  Epinfo.x:=-1;
  Epinfo.y:=-1;
  epInfo.errId:=E_none;


 gar:=EPprecompile(EpInfo,gar);
 // showmessage(Epstr);
 // showmessage(str);
 // for i:=0 to high(gar) do showmessage(gar[i]);
 // gar:=EpDecompose(str,false);
  OperateInt(EpInfo,gar,rinfo);
  EpInfo.ErrRigthLnCount:=0;
  str:='';
  if (EpInfo.ErrId<>E_None) and (not(EpInfo.ErrDeclationMode=errAlternative)) then
  begin
     gar2:=EpParse(Epstr,false);
     for i:=(EpInfo.ErrPos+1) to high(gar)  do  str:=str+gar2[i];
     EpInfo.ErrRigthLnCount:= xcount_delimiter(#10#13,str); {car par defaut xcount_delimiter donne 0  sil ne trouve de correcpondance}
     for i:=0 to (EpInfo.ErrPos)  do str:=str+gar2[i] ; EpInfo.ErrStrPos:=length(str);
     //showmessage(str+'___'+inttostr(Epinfo.ErrRigthLnCount));
  end;


  result:=EpInfo.ErrId;
end;  *)

begin
  {1er cas: do <token>while<condition>}
  if EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_token then
  begin
     repeat
        new(s_inf);
        new(dresult);
        fillEpInfo(s_inf);
        fillrinfo(dresult);
        EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
        s_inf.x:=EpInfo.x+1;
        OperateInt(s_inf,Eparr,dresult);
        freerinfo(dresult);

        //showmessage(inttostr(dresult.intvalue)+'actu value');
        if (s_inf.ErrId<>E_NONE) then SignalError(EpInfo,s_inf.ErrPos,s_inf.ErrId,s_inf.ErrParams);
        new(dresult);
        new(s_inf);
        EpInfoCopy(s_inf,EpInfo);//s_inf^:=Epinfo^;
        fillrinfo(dresult);
        s_inf.cmd:=work_REPEAT_WHILE_CONDITION;
        s_inf.silentMode:=true;
        scr_EvalEp(EpInfo.scr.instructions[EpInfo.scr.index+1].text,dresult,false,s_inf,nil);
        if s_inf.ErrId<>E_none then {passe les informations d'erreur de l'intruction contenant "while" dans EpInfo en cours}
        begin
                      EpInfo.ErrDeclationMode:=ErrAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=s_inf.ErrId ;
                      EpInfo.ErrPos:=EpInfo.scr.instructions[epInfo.scr.index+1].position;
                      EpInfo.ErrPos:=Epinfo.ErrPos-EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      if assigned(s_inf.ErrParams) then EpInfo.ErrParams:=E_STRING(s_inf.ErrParams);
                      EpInfo.ErrLn:=-1;
                     // signalError(EpInfo,s_inf.ErrPos,s_inf.ErrId,s_inf.ErrParams);
        break;
        end;

        if s_inf.cmd=work_REPEAT_WHILE_CONDITION then
        signalError(EpInfo,s_inf.ErrPos, E_REPEAT_SYNTHAX,s_inf.ErrParams);
        {erreur de synthax car après "do" la prochaine instruction doit être while}
        //showmessage('first');
        if s_inf.cmd=work_REPEAT_continue then
        //showmessage('can''t continue');
     until (s_inf.cmd=work_REPEAT_Break);
     EpInfo.scr.cmd:=scr_cmd_jumpline;
     EpInfo.x:=EpInfo.y;
     freeEpinfo(s_inf);
     freerInfo(dresult);

  end
  else
  {2eme cas: do <bloc d'instructions> while<condition>}
  if EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc then
  begin
      repeat
                    new(scr);
                    fill_scr(scr,epinfo.group,EpInfo.PID);
                    scr.IncorporetedScript:=EpInfo.IncorporetedScript;
                    scr._type:=scr_embedded;
                    scr.silenceMode:=true;
                    scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,Epinfo.PID);
                    //showmessage('hjhj');
                    //EpInfo.scr_cmd:=scr_cmd_jumpline;
                    {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
                    if (scr.error_id<>e_None) then
                    begin
                     //showmessage(scr.error_msg+' error');

                      EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=scr.error_id ;
                      EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      //showmessage(inttostr(scr.instructions[i].position))
                      //showmessage(inttostr(Epinfo.errPos));
                      EpInfo.ErrParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
                      //showmessage(epInfo.ErrParams+' error test');
                      EpInfo.ErrLn:=scr.error_line;//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
                       break;
                    end;
                    new(s_inf); new(dresult);
                    fillrinfo(dresult);
                    fillEpInfo(s_inf);
                    EpInfoCopy(s_inf,EpInfo);//s_inf^:=EpInfo^;
                    s_inf.cmd:=work_REPEAT_WHILE_CONDITION;
                    s_inf.silentMode:=true;
                    Scr_EvalEp(EpInfo.scr.instructions[EpInfo.scr.index+2].text,dresult,false,s_inf,nil);
                    if s_inf.ErrId<>E_none then {passe les informations d'erreur de l'intruction contenant "while" dans EpInfo en cours}
                    begin
                      EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
                      EpInfo.ErrId:=s_inf.ErrId ;
                      EpInfo.ErrPos:=EpInfo.scr.instructions[epInfo.scr.index+2].position;
                      EpInfo.ErrPos:=Epinfo.ErrPos-EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
                      if assigned(s_Inf.ErrParams) then EpInfo.ErrParams:=E_STRING(s_inf.ErrParams);
                      EpInfo.ErrLn:=-1;
                      // signalError(EpInfo,s_inf.ErrPos,s_inf.ErrId,s_inf.ErrParams);
                      break;
                    end;
                    if s_inf.cmd=work_REPEAT_WHILE_CONDITION then
                    signalError(EpInfo,s_inf.ErrPos, E_REPEAT_SYNTHAX,s_inf.ErrParams);
                    //showmessage(inttostr(s_inf.cmd));
      until s_inf.cmd=work_REPEAT_BREAK;
      if (epInfo.scr.cmd<>scr_cmd_abort) then Epinfo.scr.cmd:=scr_cmd_jump_to;
      EpInfo.scr.index:=EpInfo.scr.index+2;
      freeEpInfo(s_inf);
      freeRinfo(dresult);
  end;


end;

{fonction qui permet d'évaluter l'operateur do..while}
function eval_try(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
       scr:PscrInfo;
begin
        new(scr);
        fill_scr(scr,epInfo.group,EpInfo.PID);
        scr.IncorporetedScript:=EpInfo.IncorporetedScript;
        scr.silenceMode:=true;
        scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,Epinfo.PID); {a revoir: revu e O2.avril 2010}
         //showmessage('hjhj');
        //EpInfo.scr_cmd:=scr_cmd_jumpline;
        {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
        if (scr.error_id<>e_None) then
        begin
         //showmessage(scr.error_msg+' error');

          (*EpInfo.AlternativeErrorDeclaration:=true;{indique qu'on la déclaration alernative des erreurs}
          EpInfo.ErrId:=scr.error_id ;
          EpInfo.ErrPos:=scr.error_pos+EpInfo.scr_scr[epInfo.scr_index].position;  {ajoute la postion de l'instruction geniteur}
          //showmessage(inttostr(scr.instructions[i].position))
          //showmessage(inttostr(Epinfo.errPos));
          EpInfo.ErrParams:=scr.error_msg;
           //showmessage(epInfo.ErrParams+' error test');
          EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
          *)
          EPinfo.scr.cmd:=work_TRY_FUNC;
         end
         else
         begin
           if (scr.cmd=scr_cmd_abort) then   EpInfo.scr.cmd:=scr.cmd else EPinfo.scr.cmd:=work_TRY_FINALY;
         end;
        
end;
{fonction qui permet d'évaluter l'operateur try..catch}
function eval_catch(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
       scr:PscrInfo;
begin

        if (EpInfo.scr.cmd<>wait_TRY_OP) then
        begin
          SignalError(EpInfo,EpInfo.x,E_TRY_CATCH_SYNTHAX,'');
          exit;
        end;
        new(scr);
        fill_scr(scr);
        scr.silenceMode:=true;
        scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,epInfo.PID); {a revoir: revu e O2.avril 2010}
         //showmessage('hjhj');
        //EpInfo.scr_cmd:=scr_cmd_jumpline;
        {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
        if (scr.error_id<>e_None) then
        begin
        //showmessage(scr.error_msg+' error');

          EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
          EpInfo.ErrId:=scr.error_id ;
          EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
          //showmessage(inttostr(scr.instructions[i].position))
          //showmessage(inttostr(Epinfo.errPos));
          EpInfo.errParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
           //showmessage(epInfo.ErrParams+' error test');
          EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
         end;
         if (scr.cmd=scr_cmd_abort) then  EpInfo.scr.cmd:=scr.cmd     else EpInfo.scr.cmd:=work_try_catch;

end;
{fonction qui permet d'évaluter l'operateur try..finaly}
function eval_finaly(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
       scr:PscrInfo;
       str:string;
begin

        if (EpInfo.scr.cmd<>wait_TRY_OP)and (EpInfo.cmd<>wait_TRY_FINALY)and (EpInfo.cmd<>wait_TRY_FINALY_FACULTATIF)  then
        begin
          SignalError(EpInfo,EpInfo.x,E_TRY_FINALY_SYNTHAX,'');
          exit;
        end;
        new(scr);
        fill_scr(scr);
        scr.IncorporetedScript:=EpInfo.IncorporetedScript;
        
        str:=string(Epinfo.group)+scr.Name;
        scr.Name:=pgchar(str);
        scr.silenceMode:=true;
        scr_evalEx(epInfo.scr.instructions[epInfo.scr.index+1].text,scr,epInfo.PID); {a revoir: revu e O2.avril 2010}
         //showmessage('hjhj');
        //EpInfo.scr_cmd:=scr_cmd_jumpline;
        {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
        if (scr.error_id<>e_None) then
        begin
        //showmessage(scr.error_msg+' error');

          EpInfo.ErrDeclationMode:=errAlternative;{indique qu'on la déclaration alernative des erreurs}
          EpInfo.ErrId:=scr.error_id ;
          EpInfo.ErrPos:=scr.error_pos+EpInfo.scr.instructions[epInfo.scr.index].position;  {ajoute la postion de l'instruction geniteur}
          //showmessage(inttostr(scr.instructions[i].position))
          //showmessage(inttostr(Epinfo.errPos));
          EpInfo.ErrParams:=E_STRING(scr.error_msg);//strcopy(EpInfo.ErrParams,pchar(scr.error_msg));
           //showmessage(epInfo.ErrParams+' error test');
          EpInfo.ErrLn:=scr.error_line//+xcount_delimiter(#13#10,copy(scr.texte,0,EpInfo.scr_scr[epInfo.scr_index].position));
         end;
         if (scr.cmd=scr_cmd_abort) then  EpInfo.scr.cmd:=scr.cmd   else  EpInfo.scr.cmd:=work_try_finaly;
end;

{fonction qui permet d'évaluer les includes}
function eval_include(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    s_info:Pepinfo;
    dresult:Prinfo;
    filepath:string;
    scr:pscrInfo;
begin
    new(s_info);
    new(dresult);
    fillrinfo(dresult);
    fillEpInfo(s_info);
    EpInfoCopy(s_info,Epinfo);//s_info^:=EpInfo^;
    //showmessage('jk include');
    inc(s_info.x);
    operateint(s_info,Eparr,dresult);
    copyEpError(s_info,EpInfo);
    {
    EpInfo.ErrId:=s_info.ErrId;
    EpInfo.ErrPos:=s_info.ErrPos;
    EpInfo.ErrParams:=E_STRING(s_info.ErrParams);
    }
    if (dresult.rtype<>vt_char) then
    signalError(EpInfo,EpInfo.x+1,E_Incompatible,'',s_info.ErrDeclationMode)
    else
    if (s_info.ErrId=E_None) then
    begin
      filepath:=dresult.charvalue;
      //showmessage('jk include____'+filepath);
     // loadcode(filepath,epInfo.groupIndex);
     // loadcode(filepath,-1);
     new(scr);
     Fill_scr(scr);
     scr.Name:='';{sera automatiquement defini}
     if (LowerCase(Eparr[EpInfo.x])='includeonce') then scr.parent:='' else scr.parent:=EpInfo.group;
     if (LowerCase(Eparr[EpInfo.x])='includehtml') then
     begin
       {todo include html}
     end;
     scr.silenceMode:=true;
     if LoadCodeEx(filepath,scr.parent,scr)=-1 then
     signalError(EpInfo,EPInfo.x,E_PERSONAL,format('can not load file "%s"',[filepath]));
     //showmessage(scr.name);
     addScrDependency(EpInfo.PID,EpInfo.group, scr.Name);
     if scr.error_id<>E_NONE then
     begin
        EpInfo.ErrDeclationMode:=errnamespace;
        Epinfo.ErrNamespace:=E_STRING(scr.Name);
        Epinfo.ErrId:=scr.error_id;
     end;
    end;
    //if dresult.rtype=vt_char then showmessage(inttostr(s_info.ErrId));
    freeEpInfo(s_info);
    freeRinfo(dresult);

end;

{fonction qui permet d'evaluer un include et de renvoyer le result (format txt/html) dans le second screen}
function eval_includeAsHtmlDlg(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  i:integer;
  back:boolean;
begin
  if evalEventsHooks=nil then evalEventsHooks:=Tlist.Create;
  for i:=0 to evalEventsHooks.count-1 do
  if  CanAccessProc(PEvalEventHook(evalEventsHooks[i]).PID,EpInfo.Pid)  then
    try
       back:=PEvalEventHook(evalEventsHooks[i]).switchToSecondScreen;
       PEvalEventHook(evalEventsHooks[i]).switchToSecondScreen:=true;
       eval_include(EpInfo,Eparr,rinfo);
       PEvalEventHook(evalEventsHooks[i]).switchToSecondScreen:=back;

    except
        result:=-1;
    end;

end;

{fonction qui permet d'évaluer les namespaces}
function eval_namespace(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    s_info:Pepinfo;
    dresult:Prinfo;
    filepath:string;
    scr:PscrInfo;
    NewNs:string;
begin
   new(scr);
    if EpInfo.x+1>high(Eparr)  then
    begin
      signalError(EpInfo,EpInfo.x+1,E_SYNTAX,'');
      exit;
    end;
   new(s_info);
   new(dresult);
   fillEpinfo(s_info);
   fillrinfo(dresult);
   EpinfoCopy(s_info,Epinfo);//s_info^:=EpInfo^;
   inc(s_info.x);
   s_info.silentMode:=true;
   s_info.cmd:=work_NAMESPACEDef;
   operateint(s_info,eparr,dresult);
   if s_info.ErrId<>E_NONE then
   begin
     copyEpError(s_info,EpInfo);
     exit;
   end;
   if dresult.rtype=vt_NamespaceRef then
   newNs:=dresult.reference;
   if (pos('.',newNs)=0) and (length(newNs)>0) then  newNs:=string(EpInfo.group)+'.'+newNs; {definition nom namespace}

   scr.cmd:=-1;
   scr.error_id:=-1;
   //scr.ParentIndex:=EpInfo.groupIndex;
   scr.parent:=EpInfo.group;
   scr.IncorporetedScript:=EpInfo.IncorporetedScript;
   scr.heritedNameSpace:=Epinfo.group;
   scr.silenceMode:=true;
   scr.Name:=Pgstring(newNs);
   scr._type:=scr_namespace;
   //showmessage('namespace');
   //showmessage(func.groupe+'____'+func.name);
   scr.scrFilePos:=PInstruction(EpInfo.scr.instructions[EpInfo.scr.index+1]).startpos;
   scr.scrFileName:='#parent#';
   scr.defaultMemberAccess:=apublic;
   //scr2.namespace:='#tmp#'+inttosstr(lastnamespaceId+1);
   EpInfo.ErrId:=scr_evalEx(EpInfo.scr.instructions[EpInfo.scr.index+1].text,scr,epInfo.PID);
   PInstruction(EpInfo.scr.instructions[EpInfo.scr.index+1]).state:=itraited;
   {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
   if (scr.error_id<>e_None) then
   begin

                     EpInfo.ErrDeclationMode:=errnamespace;
                     Epinfo.ErrNamespace:=E_STRING(scr.Name);
                     Epinfo.ErrId:=scr.error_id;
                     //showmessage('line:'+inttostr(scr.error_line));
                     //showmessage('errreur fonction'+ scr.error_msg+ ' '+ inttostr(EpInfo.ErrId));


   end ;
   EpInfo.x:=Epinfo.x+1;
    if (scr.cmd=scr_cmd_abort) then   EpInfo.scr.cmd:=scr.cmd  else epinfo.scr.cmd:=scr_cmd_jumpline;
   checkFunctionDeclaration(scr.Name,scr.PID);
   freeEpInfo(s_info);
   freeRinfo(dresult);

end;
{fonction qui permet d'évaluter "extend" dans la declaration d'une classe}
function eval_classExtend(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    s_info:Pepinfo;
    dresult:Prinfo;
    ns:string;
begin
  if EpInfo.cmd<>work_CLASSDEF then
  begin
    signalError(EpInfo,EpInfo.x,E_PERSONAL,'Unappropriete use of "extend" operator');
    exit;
  end;

   new(s_info);
   new(dresult);
   fillEpInfo(s_info);
   fillrinfo(dresult);
   EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^;
   inc(s_info.x);
   s_info.silentMode:=true;
   //s_info.cmd:=work_NAMESPACEDef;
   s_info.cmd:=workNone;
   operateint(s_info,eparr,dresult);
   if s_info.ErrId<>E_NONE then
   begin
     copyEpError(s_info,EpInfo);
     exit;
   end;
   if (dresult.rtype<>vt_NamespaceRef) then
   begin
     SignalError(EpInfo,EpInfo.x,E_PERSONAL,'object or class not found for extend operator');
   end;
   ns:=dresult.reference;
   {rinfo.isReference:=true;
   rinfo.reference:=ns;
   rinfo.rtype:=vt_namespaceRef;  }
   rinfo.group:=E_STRING(ns);{definit le herited namespace}
   epinfo.x:=EpInfo.y;
   freeEpInfo(s_info);
   freeRinfo(dresult);


end;
{fonction qui permet d'évaluer la déclaration d'une classe}
function eval_classDeclaration(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    scr:PscrInfo;
    nsId:integer;
    newNs,hns:string;
    s_info:PEpInfo;
    dresult:Prinfo;

begin
   new(scr);
   fill_scr(scr);
   new(s_info);
   new(dresult);
   fillEpInfo(s_info);
   fillrinfo(dresult);
   EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^;
   inc(s_info.x);
   s_info.silentMode:=true;
   s_info.cmd:=work_CLASSDEF;
   dresult.name:='';{pour le class name def}
   operateint(s_info,eparr,dresult);
   if s_info.ErrId<>E_NONE then
   begin
     copyEpError(s_info,EpInfo);
     exit;
   end;
   newNs:=Eparr[EpInfo.x+1];{par defaut}
   if dresult.rtype=vt_NamespaceRef then
   newNs:=dresult.reference;
   if (pos('.',newNs)=0) and (length(newNs)>0) then  newNs:=string(EpInfo.group)+'.'+newNs; {definition nom class(identique avec namespace)}
   hns:=dresult.group;
  // showmessage(NewNs);
   {
    if (EpInfo.x+3)<=high(Eparr) then
    begin
      if EParr[EpInfo.x+2]='extend' then
      scr.heritedNameSpace:=Eparr[EpInfo.x+3];
    end;
    }
    if indexFromNameSpace(newNs,EpInfo.PID)<>-1 then
    signalError(EpInfo,EpInfo.x,E_PERSONAL,'class already exist');
    scr._type:=scr_class;
    scr.parent:=EpInfo.group;
    scr.IncorporetedScript:=EpInfo.IncorporetedScript;
    scr.Name:=Pgstring(newNs);
    scr.silenceMode:=true;
    scr.scrFileName:='#parent#';
    //scr.heritedNameSpace:=scr_ExtractParent(epInfo.PID,scr.Name);
    scr.heritedNameSpace:=hns;
    //showmessage(scr.heritedNameSpace);
    scr.defaultMemberAccess:=aPublic;  {A CORRIGER}
    nsId:=IndexFromNameSpace(EpInfo.group,EpInfo.PID);
    scr.scrFilePos:=PscrInfo(namespacelist[nsId]).instructions[EpInfo.scr.index+1].startpos;
    if (string(EpInfo.group)<>'') then
    if  (PScrInfo(namespacelist[nsId])._type<>scr_namespace) and (PScrInfo(namespacelist[nsId])._type<>scr_run) then
    begin
      SignalError(EpInfo,EpInfo.x,E_Personal,'unable to declare a classe outside of namespace');
      exit;
    end;
    if (EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc) then
    Scr.texte:=EpInfo.scr.instructions[EpInfo.scr.index+1].text;
   // showmessage(scr.texte);

    Scr_EvalEx(scr.texte,scr,EpInfo.PID);
    if (scr.error_id<>e_None) then
    begin
           EpInfo.ErrDeclationMode:=errnamespace;
           Epinfo.ErrNamespace:=E_STRING(scr.Name);
           Epinfo.ErrId:=scr.error_id;
    end;
    checkFunctionDeclaration(scr.Name,scr.PID);
    epinfo.scr.cmd:=scr_cmd_jumpline;
    epinfo.x:=Epinfo.y;
    freeEpInfo(s_info);
    freeRinfo(dresult);
end;



(*
{fonction qui permet d'évaluer une nouvelle instance d'une classe}
function eval_new_instance(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    s_info:Pepinfo;
    dresult:Prinfo;
    scr:PscrInfo;
begin
    new(scr);
    if EpInfo.x+1>high(Eparr)  then
    begin
      signalError(EpInfo,EpInfo.x+1,E_SYNTAX,'');
      exit;
    end;
   scr.cmd:=-1;
   scr.error_id:=-1;
   scr.ParentIndex:=EpInfo.groupIndex;
   scr.parentNamespace:=EpInfo.group;
   scr.silenceMode:=true;
   scr.Namespace:=Eparr[EpInfo.x+1];{equivalent à getNewNamespacestr()}
   //showmessage(string(func.groupe)+'____'+func.name);
   scr.scrFilePos:=PInstruction(EpInfo.scr_scr[EpInfo.scr_index+1]).startpos;
   scr.scrFileName:='#parent#';
   //scr2.namespace:='#tmp#'+inttosstr(lastnamespaceId+1);
   EpInfo.ErrId:=scr_evalEx(EpInfo.scr_scr[EpInfo.scr_index+1].text,scr);
   {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
   if (scr.error_id<>e_None) then
   begin

                     EpInfo.ErrDeclationMode:=errnamespace;
                     Epinfo.ErrNamespace:=scr.Namespace;
                     Epinfo.ErrId:=scr.error_id;
                     //showmessage('line:'+inttostr(scr.error_line));
                     //showmessage('errreur fonction'+ scr.error_msg+ ' '+ inttostr(EpInfo.ErrId));


   end
end;
*)
{fonction qui permet d'évaluer une nouvelle instance d'une classe}
function eval_new_instance(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
    s_info:Pepinfo;
    dresult:Prinfo;
    scr:PscrInfo;
    nsId:integer;
    ClassNs:string;
    paramlist:tlist;
begin
    new(scr);
    new(dresult);
    new(s_info);
    fillEpInfo(s_info);
    EpInfoCopy(s_info,EpInfo);//s_info^:=EpInfo^;
    inc(s_info.x);
    s_info.BreakChar:='(';
    fillrinfo(dresult);
    operateint(s_info,Eparr,dresult);
    //showmessage(dresult.reference);
    if (dresult.isReference) and (dresult.rtype=vt_namespaceRef) then
    begin
        nsid:=IndexFromNameSpace(dresult.reference,EpInfo.PID);
        ClassNs:=dresult.reference;
        if nsid<>-1 then
        if PScrInfo(namespacelist[nsid])._type<>scr_class then
        begin
          signalError(Epinfo,EpInfo.x,E_PERSONAL,'Can''t get new instance of this object');
          exit;
        end;
    end;
    fill_scr(scr,epInfo.group,epInfo.PID);
    scr._type:=scr_class_instance;
    scr.parent:=EpInfo.group;
    scr.IncorporetedScript:=EPInfo.IncorporetedScript;
    scr.heritedNameSpace:=Pgstring(classNs);
    //showmessage(scr.heritedNameSpace);
    //showmessage(scr.name+'__new class instance');
   { if EpInfo.x+3=high(Eparr) then
      if (Eparr[EpInfo.x+1]='(') and (Eparr[EpInfo.x+3]=')') then
      scr.heritedNameSpace:=Eparr[EpInfo.x+2];
   }
   addNamespace(scr.PID,scr,scr.Name,true);
   
   {clonage des variables}
   //showmessage(scr.heritedNameSpace+'___'+scr.Name);
   ns_varClone(scr.PID,scr.heritedNameSpace,scr.Name,true,clmclass);
   //ns_functionClone(scr.PID,scr.heritedNameSpace,scr.Name,true,clmclass);
   {appelle contructor}
   paramlist:=Tlist.Create;
   if s_info.x<high(Eparr) then
   begin
     s_info.BreakChar:='';
     //if s_info.ErrId<>-1 then    showmessage('error in runfunction');
     if EParr[s_info.x]='(' then dec(s_info.x);
     
     EvalArgs(Paramlist,s_info,EParr);
     if s_info.ErrId<>-1 then
     copyEpError(s_info,epInfo);
     //showmessage('class constructor paramcount:'+inttostr(paramlist.Count));
   end;
   s_info.group:=E_STRING(scr.Name);
   freeRinfo(dresult);
   new(dresult);
   fillrinfo(dresult);
   RunFunction('__construct',s_info,paramlist,dresult);
   freeRinfo(dresult);
   if paramlist<>nil then paramlist.Free;
   {fin constructor calling}
   {retour}
   rinfo.rtype:=vt_new_class_instance;
   strcopy(rinfo.name,pevchar(scr.Name));
   rinfo.isReference:=true;
   rinfo.reference:=E_STRING(scr.Name);
   {Ajout parent}
   new(dresult);
   fillrinfo(dresult);
   dresult.name:='parent';
   dresult.isReference:=true;
   dresult.reference:=E_STRING(scr.heritedNameSpace);
   dresult.rtype:=vt_classRef;
   dresult.isReference:=true;
   dresult.group:=E_STRING(scr.Name);
   Setvar(epInfo.PID,dresult,true);
   {ajout this}
   new(dresult);
   fillrinfo(dresult);
   dresult.name:='this';
   dresult.isReference:=true;
   dresult.reference:=E_STRING(scr.Name);
   dresult.rtype:=vt_classRef;
   dresult.isReference:=true;
   dresult.group:=E_STRING(scr.Name);
   Setvar(epInfo.PID,dresult,true);
   EpInfo.x:=EpInfo.y;
end;
{evalue les reference au elements d'une classe précédés par (::)}
function eval_scope_resolution(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   scr:PscrInfo;
begin
  if (Eparr[EpInfo.x]=':') and (EpInfo.x+1>high(Eparr)) then
  begin
  signalError(EpInfo,EpInfo.x,E_Syntax,'scope use');
  exit;
  end;
  //if (Eparr[EpInfo.x+1]=':') then
  //if rinfo.rtype=vt_namespaceRef then
  //showmessage('scope '+rinfo.name+'__'+Eparr[EpInfo.x+1]);
  if (rinfo.rtype<>vt_namespaceRef) or (Eparr[EpInfo.x+1]<>':')then
  begin
    //if rinfo.rtype<>vt_namespaceRef then showmessage('hjhjjkjkjk');
    //showmessage('kjkj'+Eparr[Epinfo.x+1]+EParr[EpInfo.x]) ;
    signalError(EpInfo,EpInfo.x,E_Syntax,rinfo.name+'_____');
  end
  else
    inc(epinfo.x);
end;
{evalue l'operateur '.'}
function eval_point_operator(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   scr:PscrInfo;
begin
  if (Eparr[EpInfo.x]='.') and (rinfo.rtype=vt_char) then
  dconcact(EpInfo,Eparr,rinfo)
  else
  if (rinfo.rtype<>vt_namespaceRef) then
  begin
   signalError(EpInfo,EpInfo.x,E_Syntax,'Utilisation incorrecte de l''operateur "."');
  end;

end;

{fonctio qui permet d'évaluer "use" methode}
function eval_use(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
   nsId:integer;
   dresult:Prinfo;
   ns:string;
begin

  new(dresult);

  ns:=Eparr[Epinfo.x+1]; {par defautl}
  inc(EpInfo.x);
  fillrinfo(dresult);
  operateint(EpInfo,Eparr,dresult);

  if dresult.rtype=vt_namespaceRef then
  ns:=dresult.reference;
  //showmessage(ns);
  nsId:=indexFromNamespace(ns,EpInfo.PID);
  if nsId=-1 then
  SignalError(EpInfo,Epinfo.x,E_Personal,format('unenable to find namespace %s',[Eparr[Epinfo.x]]))
  else
  addScrDependency(EpInfo.PID,Epinfo.group,ns);
  freeRinfo(dresult);
end;
{fonction qui permet d'évaluer les fonction qui créee et font en même tant reference
a ces variables
par exemple: var ab=function{echo "delpi";}
function eval_UserhiddenFunc(Epinfo:Pepinfo;Eparr:strarr;rinfo:Prinfo):integer;
var
  func:Pfunc;
  paramStr:string;
  Pend:integer;
  i:integer;
begin
  new(func);
  fillfunc(func);
  showmessage('jkjk:function hidden func');
  func.ftype:=ft_virtual;
  func.rtype:=vt_none;
  pend:=getParaEnd(EParr,EpInfo.x+1);
  for i:= EpInfo.x+2 to pend-1 do
  ParamStr:=ParamStr+EParr[i];
  func.params:=E_STRING(ParamStr);
  strcopy(func.name,Pchar(GetNewNameSpaceStr));{just pour avoir un nom aléatoire}
  if EpInfo.scr.instructions[EpInfo.scr.index]._type=instruct_prebloc then
  func.v_location:=EpInfo.scr.index+1
  else
  signalError(EpInfo,EpInfo.x,E_PERSONAL,'function declaration error: you must put a bloc "{}"');
  EpInfo.scr.instructions[EpInfo.scr.index+1].state:=itraited;
  func.groupe:=E_STRING(EpInfo.group);
  if (rinfo.isReference) and ((rinfo.reference='private') or (rinfo.reference='public')) then
    func.access:=rinfo.access
  else
   func.access:=GetScrMembersDefAccess(epInfo.PID,func.groupe);
  func.heritedNameSpace:=E_STRING(EpInfo.group);
  SetFunc(EpInfo.PID,func,func.name,func.groupe);
  rinfo.group:=E_STRING(func.groupe);
  rinfo.reference:=E_STRING(func.name);
  rinfo.isReference:=true;
  rinfo.rtype:=vt_funcRef;
  rinfo.name:='function';
  epinfo.x:=pend+1;
end;



function reg_scr_op():integer;
var
  op:Poperator;
begin
  if OperatorList=nil then OperatorList:=TList.Create;
  {condition}
  new(op);
  op.name:='if' ;
  op.Pop:=@eval_condition;
  OperatorList.Add(op);
  new(op);
  op.name:='else' ;
  op.Pop:=@eval_conditionElse;
  OperatorList.Add(op);
  (* {variables}
  new(op);
  op.name:='$' ;
  op.Pop:=@traiter_var;
  op.leftOp:='*';
  OperatorList.Add(op);
  
  new(op);
  op.name:='var' ;
  op.Pop:=@traiter_var;
  op.leftOp:='';
  OperatorList.Add(op);
  *)
  {boucle for}
  new(op);
  op.name:='for' ;
  op.Pop:=@eval_for;
  OperatorList.Add(op);
  {fonction break pour arreter les boucle}
  new(op);
  op.name:='break' ;
  op.Pop:=@eval_break;
  OperatorList.Add(op);
  {fonction while}
  new(op);
  op.name:='while' ;
  op.Pop:=@eval_while;
  OperatorList.Add(op);
  {fonction negation}
  new(op);
  op.name:='!' ;
  op.Pop:=@eval_negation;
  op.leftOp:='';
  OperatorList.Add(op);
  {fonction switch}
  new(op);
  op.name:='switch' ;
  op.Pop:=@eval_switch;
  OperatorList.Add(op);
  {fonction case}
  new(op);
  op.name:='case' ;
  op.Pop:=@eval_case;
  OperatorList.Add(op);
  {fonction do..while}
  new(op);
  op.name:='do' ;
  op.Pop:=@eval_do;
  OperatorList.Add(op);
  {fonction try..finaly/catch}
  new(op);
  op.name:='try' ;
  op.Pop:=@eval_try;
  OperatorList.Add(op);
  {fonction try..finaly}
  new(op);
  op.name:='finaly' ;
  op.Pop:=@eval_finaly;
  OperatorList.Add(op);
  {fonction try..catch}
  new(op);
  op.name:='catch' ;
  op.Pop:=@eval_catch;
  OperatorList.Add(op);
  {fonction include(..)}
  new(op);
  op.name:='include' ;
  op.Pop:=@eval_include;
  OperatorList.Add(op);
  {fonction printhtmldlg(..)}
  new(op);
  op.name:='printhtmldlg' ;
  op.Pop:=@eval_includeAsHtmlDlg;
  OperatorList.Add(op);

  {fonction namespace(..)}
  new(op);
  op.name:='namespace' ;
  op.Pop:=@eval_namespace;
  OperatorList.Add(op);
  {fonction ::(..)}
  new(op);
  op.name:=':' ;
  op.Pop:=@eval_scope_resolution;
  op.leftop:=':';
  OperatorList.Add(op);
  {fonction use}
  new(op);
  op.name:='using' ;
  op.Pop:=@eval_use;
  OperatorList.Add(op);
  {fonction class}
  new(op);
  op.name:='class' ;
  op.Pop:=@eval_classDeclaration;
  op.leftOp:='=';
  OperatorList.Add(op);
  {fonction class extended}
  new(op);
  op.name:='extended' ;
  op.Pop:=@eval_classExtend;
  op.leftOp:='=';
  OperatorList.Add(op);
  {fonction new}
  new(op);
  op.name:='new' ;
  op.leftOp:='=';
  op.Pop:=@eval_new_instance;
  OperatorList.Add(op);
  {fonction .}
  new(op);
  op.name:='.' ;
  op.leftOp:='"';
  op.Pop:=@eval_point_operator;
  OperatorList.Add(op);
  {fonction .}
  new(op);
  op.name:='function' ;
  op.leftOp:='public;private';
  op.Pop:=@eval_UserHiddenfunc;
  OperatorList.Add(op);

  {exit}
  new(op);
  op.name:='exit' ;
  op.Pop:=@eval_abort;
  OperatorList.Add(op);
  new(op);
  op.name:='abort' ;
  op.Pop:=@eval_abort;
  OperatorList.Add(op);
end;



end.
