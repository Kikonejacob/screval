unit eval;

 {----------------------evaluateur d'expression------------
 Cette partie contient les functions d'évaluation des expressions;
 ->Date:12.jul.2008

 ->Revision importante 25.08.2008 dans EvalArgs
 permet de supporter des functions sans paramètres
 ->revision importante 25.08.2008 dans Call_afunc
 permet de supporter les procedures
 ->Revision importante 25.05.2008 dans CheckCompatible
 Permet de supporter les procédure 25.08.2008


 REVISION 2009
 29.juil.2009
16.aout.2009
05 .avril. 2010
20.10 2010 amelioriation pour porter le code en dll;

Principe de déclaration alternatique des erreurs(uniquement pour les sripts): 5 avril 2010
-------------------------------------------------
lorsque les composants telque que la boucle for qui est enregistré composant de la 1ere couche
evaluent un bloc de code a l'aidre de ScreEval, elle ne peuvent pas entrer directement les informations
sur les erreurs eventuelle survenu lors de l'interpretation de screval. Pour cela ces composants
indiques ces information dans la structure Pepinfo et activent AlternativeScrError pour dire a EpEval
de ne pas s'occuper de l'erreur. les informations seront traiter les ScrEval mère et ensuite affichés
a l'utiliateur


11 avril 2010:

Principe de délcaration des erreur amélioré pour le support des namespaces
------------------------------------------------------------------------
Il ya eu une modification sur le mode de déclaration des erreurs. la nouvelle variable "errDeclarationMode" contenu
dans PepInfo permet d'indiquer ou l'erreur s'est deroulé afin de mieux la traiter:
si errDeclarationMode prent pour valeur errNormal cela ve dire que l'erreur s'est produite dans le même namespace;
                                        errAlternative, on utilise la déclaration alternative des erreurs
                                        errNamespace, l'erreur s'est produite dans un namespace enfant
Lorsque qu'une erreur se produit sur un namespace enfant celui-ci

 14 juillet 2010: amelioriation fonction virtuelle
 5 avril 2011 correction et ajout unsetEventHook
 10 avril  2011 Correction EventHooks
 21,22 avril namespaceRef consideration on adress function   and some corrections
 26,27 avril  corrections generales (correction bug dans scrEvalEp au niveau de la gestion des erreurs
                                    correction bug GetscrDependency);
 28 avril multiples PID;
 30 avril ,1 mars correction et amelioriation callafunc;

 03.04.2012 correction du traitement des fonction overloaded et des fonction ayant le meme nom dans un namespace et son enfant
 06.18.2013: cnvrinfotostr add Fdigit
 --------------------------------------------------------------}

interface

{$I eval.inc}
uses classes,sysutils,dialogs,math;

{ type commun des tableau de string et integer }
type Strarr=array of string;
type intarr=array of extended;
type Pgstring=string;
type Pgchar=Pgstring;
     TEvalAccess=(aPrivate,aPublic);

{Structure du resultat dans eval. structure d'une donnée dans EPeval} {rev 29.juil.2009}
type PEvChar=Pchar;
type
Prinfo=^drinfo;
drinfo=record
     IntValue:integer;
     CharValue:PChar;
     CharBuffSize:integer;
     BoolValue:Boolean;
     floatvalue:double;
     rtype:integer;
     rtypestr:array[0..256] of char;{pour vt_classtype}
     ErrId:integer;{a supprimer}
     //obj:Tobject;
     pt:Pointer;
     PID:integer;
     //olevar:olevariant; {Variables ole}
     //interf:IUnknown; {interface ole pour par exemple recordset de ADO}
     name:array[0..256] of char;
     group:Pchar;
     arrays:array of Prinfo;{pour creer un tableau }
     access:TevalAccess;
     heritedNameSpace:Pchar;
     isReference:boolean;
     reference:Pchar;
     DefaultValue:Pchar;{utilisé uniquement pour les parmètre des fonctions voir PParamInfo; }
     key:array[0..256] of char;{pour les arrays}

end;
{type classe}
type
PClassType=^dClassType;
dClassType=record
   name:string;
   classNs:string;
   ParentNamespace:string;
   PID:integer;
end;

{Info sur script}
type

Pinstruction=^dinstruction;
dinstruction=record
   text:pchar;
   bufsize:integer;
   _type:integer;
   canEval:boolean;
   position:integer;
   startpos:integer;{indique le debu du  bloc}
   state:(iUntraited,iTraited);
end;

 {Table des namespaces dépendant d'un namespace donné}
type
PNameSpaceDepends=^TNameSpaceDepends; {obsolete}
TNameSpaceDepends=record
   index:integer; // index dans la liste
   str:string;
   nextchild:PNameSpaceDepends;
end;
type
TScrDependency=array of string;
{Structure d'un namespace}
type
Pscrtype=(scr_run,scr_namespace,scr_class,scr_class_instance,scr_running_methode,scr_embedded);
type
//Pscr=array of Pinstruction;
Pinstructions =array of Pinstruction;
PscrInfo=^dscrInfo;
dscrInfo=record
   instructions:Pinstructions;
   cmd:integer;
   cmdArg:pointer;
   index:integer;{indique la postion dans le script lors de l'évalutation: a ne pas confondre avec l'index dans le namespacelist}
   error_id:integer;
   error_pos:integer;
   error_line:integer;
   error_msg:Pgchar;
   error_namespace:Pgchar;{indique le namespace dans lequel lerreur s'est produite}
   silenceMode:Boolean;{n'indique pass d'erreur sur l'écran}
   echo_str:Pgchar;{echo string}
   texte:string;
   parent:Pgchar;
   //ParentIndex:integer;{index du Namespace parent dans la liste}
   Name:Pgchar;
   //NamespaceId:integer;
   scrFileName:Pgchar;
   scrFilePos:integer;
   //childNameSpaces:PNameSpaceDepends;
   //scrChildsId:array of integer;{indique l'index de tous les namespace qui heritent de scrinfo}
   heritedNameSpace:Pgchar;
   _type:Pscrtype;
   defaultMemberAccess:TevalAccess;
   dependency:TscrDependency;
   PID:integer;{indique le numero de l'instance de l'évaluteur}
   IncorporetedScript:boolean;{specify what ever the script is incorpored in a another language}

end;

{structure alternative pour déclarer des erreurs dans le scrip: utilisé par exemple par la boucle for:
obsolete (na plus  besoin) }
PAlternativeScrError=^dAlternativeScrError;
dAlternativeScrError=record
      error_id:integer;
      error_msg:string;
      error_pos:integer;
      error_line:integer;
end;
const
      MaxListSize = Maxint div 16;
      instruct_token=0;
      instruct_bloc=1;
      instruct_prebloc=2;
      instruct_passive=3;
      instruct_printedtext=4;{permet d'imprimer le text quand l'option useprintedText est supporte}
{conteneur de pointer}
type
Plist=^dList;
dList=record
  Flist:array[0..MaxListSize - 1] of Pointer;
  count:integer;
end;



{end Info sur script}

{Structure d'une fonction dans eval.}
type
Pfunc=^dfunc;
dfunc=record
     ftype:integer;//soit adressage de function soit function dans une  dll.
     name:array[0..65] of char;
     params:Pchar; {exemple:tab:int;an:char}
     pfunc:pointer; //adresse de la function
     helpfunc:pointer; //adresse de la function d'aide
     lib:array[0..65] of char; //au cas ou c'est une function d'une dll
     rtype:integer; //type du resultat
     groupe:Pchar;
     PID:integer;
{uniquement pour les fonctions virtuelles}
     v_instruct:PInstruction;
     v_location:integer; {position de l'instruction a executer au cas d'appel de la function}
     heritedNameSpace:Pchar;
     access:TevalAccess;
end;
type
  PfuncRunningInfo=^dfuncRunningInfo;
  dFuncRunningInfo=record
     paramCount:integer;
     group:Pchar;
     ErrorId:integer;
     ErrorParam:pchar;
end;
{prototype fonction vituelle d'une application ou d'un module}
type
  Tepvfunc=procedure(PID:integer;func:pfunc;ruInfo:pointer;result:Prinfo;EPInfo:pointer);stdcall;
{structure d'un tableau 21.10.2010}
type ParrayInfo=^darrayInfo;
darrayInfo=record
   name:pgstring;
   group:pgstring;
   arrays:array of Prinfo;
end;
{Structure  d'informations sur le processus d'évaluation}
type
    TPreviewTraited=(pt_none,pt_variable,pt_const,pt_function,pt_operator); {indique la nature de la dernière colonne traitée}
    TErrorDeclarationMode=(errNormal,errAlternative,errNamespace);
type
PEpinfo=^dEpinfo;
dEpinfo=record
     ForUser:boolean;
     cmd:integer; {indique une petite tache en cours provoquée par une function de l'évaluateur}
     cArg1:array[0..256] of char;{argument du cmd}
     cArg2:integer;{argument du cmd}
     cArg3:pointer;
     traited:boolean;{traitement de boolean}
     x:integer;
     y:integer;
     ListRootStr:array[0..60] of char;
     KeyValue:integer;
     ErrId:integer;
     ErrParams:Pchar;
     ErrPos:integer;
     ErrNamespace:Pchar;{indique le namespace dans lequel s'est produit l'erreur}
     ErrLn:integer;{utilisé unique en cas declaration alternative de script}
     ErrRigthLnCount:integer;
     ErrStrPos:integer; {indique la position exacte de l'erreur dans le texte de l'expressioon}
     ErrDeclationMode:TErrorDeclarationMode;{indique le type d'erreur en fonction du lieu ou s'est produit l'erreur }
     //AlternativeErrorDeclaration:boolean;{alternative  pour déclarer un erreur dont on a deja les infos dans le script}
     BreakChar:array[0..60] of char;{si Epeval  rencontre ce charactère arrête brutalement l'expression}
     scr:PscrInfo;
     //scr_scr:Pinstructions;
     //scr_cmd:integer;
     //scr_cmdArg:pointer;
     //scr_index:integer;
     group:pchar;
     prev_traited:TPreviewTraited;
     silentMode:boolean;{n'affice pas les erreur}
     //scr_switch_info:PrInfo;{pour la structure switch}
     groupIndex:integer;
     groupParentIndex:integer;
     defaultMemberAccess:TevalAccess;
     IncorporetedScript:boolean;//view TscrInfo.IncorporetedScript for description
     PID:integer;

end;

{Structure d'un operateur}
type
Poperator=^doperator;
doperator=record
name:string;
Pop:pointer;
leftOp:string;{indique les différents opérateur qui peuvent se placé avant ce operateur} 
helpFunc:pointer;
helpId:integer;
end;
{Structure d'information sur un paramètre d'une fonction}
type
{PparamInfo=^dparamInfo;
dparamInfo=record
       pname:string;
       ptype:integer;
       rinfo:Prinfo;
end;
}
PParamInfo=Prinfo;


{Structure d'une constant dans l'évaluateur d'expression}
type
PConstInfo=^dConstInfo;
dConstInfo=record
   name:Pgstring;
   rInfo:PrInfo;
   groupe:Pgstring;
end;

{Structure d'une variable dans l'évaluateur d'expression}
type
PvarInfo=Prinfo;
{struction d'informations pour la rechercher d'un fonction 1.09.2010}
type PFuncSearchInfo=^dFuncSearchInfo;
dFuncSearchInfo=record
   DeclarationArgList:Tlist;
   ParamList:Tlist;
end;

{Structure d'information sur un processus d'evaluation }
type
PevalProcessInfo=^devalProcessInfo;
devalProcessInfo=record
   PID:integer;
   AppHandle:Thandle;
   Locked:boolean;
end;
type
PevalEventHook=^devalEventHook;
devalEventHook=record
   PID:integer;
   ScreenHandler:pointer;
   SecondScrHandler:pointer;
   Data:pointer;
   EvalStatusHandler:pointer;
   AppHandle:Thandle;
   SwitchToSecondScreen:boolean;
   cbsize:integer;
end;
{prototype d'un fonction screeProc}
type
   TEvalStreamProc=function(text:pchar;buffSize:integer;data:pointer):integer;stdcall;
{constante clonage function et variable}
TEvalCloneMode=(clmSingle,clmClass,clmClassInstance);
{Constantes d'erreurs}
const
      E_NoAllArgs=1;
      E_NoCharEnd=2;
      E_NoParaEnd=3 ;
      E_Syntax=4;
      E_divError=5;
      E_OpError=6;
      E_Incompatible=7;
      E_Extra=8;
      E_IF_ARGCOUNT=9;
      E_FOR_ARGCOUNT=10;
      E_WHILE_ARGCOUNT=11;
      E_PARA_WANTED=12;
      E_UnknowSymbol=13;
      E_SWITCH_SYNTHAX=14;
      E_SWITHC_ARG_TYPE=15;
      E_UNAPPROPRIETED_USEOFBREAK=16;
      E_CASE_TYPE_INVALID=17;
      E_CASE_SYNTHAX=18;
      E_REPEAT_SYNTHAX=19;
      E_REPEAT_WHILE_SYNTHAX=20;
      E_TRY_SYNTHAX =21;
      E_TRY_CATCH_SYNTHAX=22;
      E_TRY_FINALY_SYNTHAX=23;
      E_Parse_ERROR=24;
      E_FUNCTION_ARG=25;
      E_PERSONAL=1000;

      E_None=-1;

{Operateur}
//const Opstr='+;-;(;);*;/;&;<;>;=;";,;.;[;];:;'+'!;$;%,%;!; ;';  (sauvegarde)
const Opstr='+;-;(;);*;/;&;<;>;=;";,;.;[;];:;'+'!;$;%,%;!; ;'';?>;<?;^;';

{Const cmd de eval}
const WorkAddition=0;{permet de respecter la priorité de (+et/) sur(+et-)}
      WorkNone=-1;
      workUntil=1;{arrete l'evaluation si caractère spécifié rencontré}
      workabort=2;
      work_BOUCLE_END=3;{intervient lors de l'appel de break pour arrêter une boucle for ,while}
      work_SWITCH=4;
      work_CASE=5;
      work_REPEAT_WHILE_CONDITION=6;
      work_REPEAT_BREAK=7;
      work_REPEAT_CONTINUE=8;
      work_TRY_FUNC=9;
      Work_TRY_CATCH=10;
      work_TRY_FINALY=11;
      wait_TRY_OP=12;
      wait_TRY_CATCH=13;
      wait_TRY_FINALY=14;
      wait_TRY_FINALY_FACULTATIF=15;
      work_NAMESPACEDef=16;
      work_CLASSDEF=17;
{def const pour scrip eval}
const scr_cmd_abort=18;
      scr_cmd_jumpline=19;
      scr_cmd_error=20;
      scr_cmd_jump_to=21;
      FUNC_SIMULATION_PARAMS='#hiddenFuncSimulation#';
{fin const script eval }
{def const pour dbdata}
     workdb_setvalue=22;
     workdb_getvalue=23;
{fin dbdata}
     work_SETPREVIEWTRAITED=22;
     workUntilType         =23;
     WORK_CONDITION_TRUE   =24;
     WORK_CONDITION_FALSE  =25;
     WORKED_CONDITION_TRUE =26;
     WORKED_CONDITION_FALSE=27;
{Liste des constantes pour scr}
const
     SCR_CMD_SWITCH=Work_SWITCH;
     SCR_CMD_CASE=work_CASE;
{Listes des function,constantes,opérateur, de eval}
 
var funcList:Tlist;
var constList:Tlist;
var OperatorList:TList;
var varlist:TList;
var typelist:Tlist; {class types list}
var evalProcessList:TList;
    evalEventsHooks:Tlist;
    namespaceList:Tlist;
    arraylist:Tlist;
    IsEvalInit:boolean;
    lastnamespaceID:integer;{pour permettre l'autoincrementation des namespace lors de la déclaration}

{type de fonction}
const ft_Adress=0;
const ft_dll=1;
      ft_virtual=2;
      ft_virtual2=3;
{Type de resultat}
const vt_integer=0;
      vt_Char=1;
      vt_bool=2;
      vt_float=3;
      vt_date=4;
      vt_numeric=5;
      vt_dbdata=6;
      vt_none=-1;
      vt_array=7;
      vt_array_row=8;
      vt_namespaceRef=9;
      vt_classRef=vt_namespaceRef;
      vt_new_class_instance=10;
      vt_funcRef=11;
      vt_type=12;
      vt_null=13;
      rt_pointer=14;{type réel pointer}
      rt_Prinfo=15;{type réel return une structure Prinfo}
      vt_classType=16;{type class}

{ROot PID}
const
      ROOT_PID=$00000;

{RINFO text operation}
const
    TextOperation_copy =$00000;
    TextOperation_cat  =$00001;
{pour dbdata}
type
  DataFunc=function(cmd:integer;group:pchar;arg:prinfo;rinfo:prinfo):integer;

{lister de func,var,namespace }
type
  Funclister=function(func:Pfunc):boolean; stdcall;
  varlister=function(varinfo:Pvarinfo):boolean; stdcall;
  namespacelister=function(name:pchar;rcount:integer):boolean;stdcall;




{pour les cmd}
const Cpermanent=1;

var tmpNumSerial:integer;{pour les serials}

const
  FLOAT_ILLIMITED_DIGIT=-50;   {pour les conversion de rinfo to str}


function OperateInt(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function EvalOperator(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function EvalFunction(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function EvalConst(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function EvalExtra(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function GetArgInfo(PID:integer;finfo:Pfunc;ArgList:Tlist):integer;
function StrTortype(str:string):integer;
function rtypeToStr(rtype:integer):string;
function rtypeToStrEx(rinfo:Prinfo):string;

function PlaceValue(initr,endr:Prinfo;Move:boolean):integer;
function EvalArgs(ParamList:Tlist;EpInfo:PepInfo;Eparr:strarr):integer;
function Call_afunc(func:Pfunc;args:PfuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;
function Changecmd(Epinfo:Pepinfo;NewCmd:integer;arg1:string;arg2:integer):integer;
function restoreEpInfo(sEpInfo,nEpInfo:pepInfo):integer;
function SaveEpInfo(EpInfo,sEpInfo:pepinfo):integer;
function SignalError(EpInfo:Pepinfo;ErrPos,ErrId:integer;ErrParams:string;DeclarationMode:TErrorDeclarationMode=errNormal):integer;
function  ManageError(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function Precompile(EpInfo:pepinfo;Eparr:strarr):string;
function EvalEp(Epstr:string;rinfo:Prinfo;ForUser:boolean):integer;
function EvalEpEx(Epstr:string;lrootStr:string;Keyvalue:integer;rinfo:prinfo;forUser:boolean;scrInfo:PscrInfo):integer;
function CheckCompatible(rinfo1,rinfo2:prinfo;rtype:integer):boolean;
function initEval:boolean;
function Fillrinfo(rinfo:prinfo):integer;
{Fonction tiré directement de geval}
function GetParaEnd(Eparr:strarr;operatorpos:integer):Integer;
function isnumeric(gstr:string):boolean;
{enregistrement function et constante ->25.08.2008}
function GetConst(name,groupe:string;rconst:Pconstinfo):integer;
function GetFunc(PID:integer;name,groupe:string;rfunc:Pfunc):integer;
function GetFuncEx(PID:integer;name,groupe:string;rfunc:Pfunc;SearchInfo:PFuncSearchInfo):integer;
function UnsetFunc(PID:integer;name,group:string):integer;

function SetConst(constinfo:PconstInfo;name,groupe:string):integer;
function SetFunc(PID:integer;func:PFunc;Name,groupe:string):integer;
function scr_EvalEp(Epstr:string;rinfo:prinfo;forUser:boolean;epInfo:PepInfo;scr:PscrInfo):integer;

function GetvarAdress(PID:integer;name,groupe:string):Pvarinfo; {06.08.2010}
function Getvar(PID:integer;name,groupe:string;rvar:PvarInfo):integer;
//function Setvar(rvar:PvarInfo):integer;
function Setvar(PID:integer;rvar:PvarInfo;const EraseExisting:boolean=false):integer;
function GetOperator(name:string;rop:POperator):integer;

function GetBlocEnd_EP(Eparr:strarr;operatorpos:integer;Beg,En:string):Integer;


function EpPrecompile(EpInfo:pepinfo;Eparr:strarr):strarr;
function xcount_delimiter(delimiter,str:string):integer;{contient la même fonction dans script.pas}
function Call_vfunc(func:Pfunc;args:PfuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;

{namespace}
function AddNamespace(PID:integer;scr:PscrInfo;name:string;AutoCreateParent:boolean):integer;
function deleteNamespace(PID:integer;namespace:string;deleteChild:boolean):integer;
//function deleteNamespace(index:integer;deleteChilds:boolean):integer;
function isChildNamespace(PID:integer;child,parent:string):boolean;
function GetScrMembersDefAccess(PID:integer;namespace:string):TevalAccess;

function IndexfromNamespace(namespace:string;PID:integer):integer;
function GetNewNameSpaceStr:string;
function SetScrNameSpace(PID:integer;namespacestr:string;newNamespaceStr:string):boolean;
function getScrDependency(PID:integer;namespace:string;includeParent:boolean):strarr;



function GetScrInfoType(PID:integer;namespace:string):PscrType;

function copyEpError(source,dest:PepInfo):integer;

function EvalNameSpaceRef(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
function isNamespaceDependency(PID:integer;dependency,namespace:string):boolean;
function addScrDependency(PID:integer;namespace,dependency:string):integer;
function fill_scr(scr:PscrInfo):integer;overload;
function fill_scr(scr:PscrInfo;parent:string;PID:integer):integer;overload;

function IndexOfNameSpace(namespace:string;PID:integer):integer;
function Find_hNamespace(PID:integer;namespaceStr,parent:string):integer;
function ns_varClone(PID:integer;namespace,destNamespace:string;includeHeritage:boolean;Mode:TEvalCloneMode):integer;
function ns_functionClone(PID:integer;namespace,destNamespace:string;includeHeritage:boolean;Mode:TevalCloneMode):integer;

function StrTortypeEx(PID:integer;str:string;rinfo:prinfo;const group:string=''):integer;
function CreatEvalProcess(ProcessInfo:PevalProcessInfo):integer;
function GetNewNumericId:integer;
function SetEvalHook(Hook:PEvalEventHook):integer;
function UnsetEvalHook(AppHandle:integer):integer;
function PrintScreenText(Pid:integer;text:string):integer;
function PrintScreenText2(Pid:integer;text:pchar):integer;

function UnsetVar(PID:integer;varStr:string;group:string):integer;
function cnv_rinfoTostr(rinfo:prinfo;const FDigit:integer=-1):string;


function array_create(PID:integer;name,group:Pgstring;access:TevalAccess):integer;
function array_setvalue(PID:integer;arr:Prinfo;group,key:pgstring;value:Prinfo):integer;
function array_deleteValue(PID:integer;arr:Prinfo;key:Pgstring):integer;
function array_delete(PID:integer;name,group:Pgstring):integer;
function array_copy(PID:integer;source,dest:pgstring):integer;
function array_getvalue(PID:integer;arr:Prinfo;group,key:pgstring):Prinfo;
function array_get(PID:integer;name,group:Pgstring):Prinfo;


function GetEpStrErrPos(Epstr:string;index:integer):integer;
function DeleteEvalProcess(PID:integer):boolean;
function CanAccessProc(PID,UserPID:integer):boolean;

function GetNamespaces(PID:integer;Parent:string;lister:pointer):boolean;
function GetFuncs(PID:integer;group:string;lister:pointer):boolean;
function Getvars(PID:integer;group:string;lister:pointer):boolean;

function Call_v2func(func:Pfunc;args:PFuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;

function class_add(PID:integer;classname,namespace,extented:string):integer;
function class_addmethode(PID:integer;classname,namespace:string;func:Pfunc):integer;
function class_addproperty(PID:integer;className,namespace:string;rinfo:prinfo):integer;
function class_delete(PID:integer;className,namespace:string):integer;
function class_deleteMethode(PID:integer;className,namespace,methodeName:string):integer;
function class_deleteProperty(PID:integer;className,namespace,propertyName:string):integer;


function RunFunction(name:string;EpInfo:PepInfo;paramlist:Tlist;fresult:Prinfo):integer;
function Instance_ExtractName(PID:integer;scrName:string):string;



function IsClassMethode(PID:integer;func:Pfunc;classname:string):boolean;

function scr_ExtractParent(PID:integer;ns:string):string;
function scr_gettype(PID:integer;ns:string):Pscrtype;

function deletefuncs(PID:integer;group:string):integer;
function deleteVars(PID:integer;group:string):integer;
function ConvertRinfoValueType(rinfo:Prinfo;rtype:integer;replacetype:boolean):boolean;


implementation
uses gutils,common,regeval{$IFDEF SCRIPTENABLE}, script,scr_reg_eval,eval_extra{$ENDIF}{,virtualfields};


{Fonction qui permet de savoir si un élement de eparr determine le
debut dune date}
function Isdate(Eparr:strarr;x:integer):boolean;
begin
  result:=false;
  if (x+4<=high(Eparr)) then
  begin
  result:=(Eparr[x+1]='/') and (Eparr[x+3]='/');
  if result then
  result:=Isnumeric(Eparr[x]) and  Isnumeric(Eparr[x+2]) and Isnumeric(Eparr[x+4])
 end;
end;

{fonction qui permet de savoir si c'est numeric}
function isnumeric(gstr:string):boolean;
var
  gi:integer;ln:string;
  m:tdatetime;
Begin
    result:=true;
    result:=(length(gstr)>0);{ici on verifie d'abord que le string n'est pas vide 07mai2010}
    For gi:=1 to length(gstr) do begin
        ln:= copy(gstr,gi,1);
        if  pos(ln,'0123456789')=0 then begin
        result:=false;break;
        end;
        m:=10/04/90
    end;

end;

{Function qui permet de savoir la longeur d'une parathèse
attendion: operatorpos indique l'operateur qui vient avant la parentèse

TODO: 30.08.2012 detection erreur  dans <If (PBeg=PEnd) then> ver la fin de la fonction
lorsque PBeg=PEnd il se peut qu'on n'ai pas trouve de parenthese dans l'expression et que
donc PBeg=0
}
 function GetParaEnd(Eparr:strarr;operatorpos:integer):Integer;
  var pBeg,pEnd,y:integer;
  begin
  y:=operatorpos;pBeg:=0; pEnd:=0;
  //showmessage(Eparr[operatorpos]+' para count');
  while  ((pBeg<>pEnd) or (pBeg=0))   and (y<=high(Eparr) )     do begin
     If Eparr[y]='(' then inc(pBeg);
     If Eparr[y]=')' then inc(pEnd);
     If (pBeg=pEnd)and (pBeg>0) then Result:=y;
     inc(y);

  end; //showmessage('beg'+inttostr(pbeg)+'end'+inttostr(pend)+ Eparr[y-1]);
 // si pBeg=pEnd appliquer la procedure ci-dessous est justifié #crer une routine d'erreur
 If (PBeg=PEnd) Then
 result:=y-1 {puisque on incremente y  dans la boucle}
 else result:=-1{Renvoie une erreur}

 end;

 {Function qui permet de savoir la longeur d'un bloc se trouve differemment das scrip.pas}
 function GetBlocEnd_EP(Eparr:strarr;operatorpos:integer;Beg,En:string):Integer;
  var pBeg,pEnd,y:integer;
  begin
  y:=operatorpos;pBeg:=0; pEnd:=0;
  while  ((pBeg<>pEnd) or (pBeg=0))   and (y<=high(Eparr) )     do begin
     If Eparr[y]=Beg then inc(pBeg);
     If Eparr[y]=En then inc(pEnd);
     If (pBeg=pEnd)and (pBeg>0) then Result:=y;
     inc(y);
  end;
 // si pBeg=pEnd appliquer la procedure ci-dessous est justifié #crer une routine d'erreur
 If PBeg=PEnd Then
 result:=y-1 {puisque on incremente y  dans la boucle}
 else result:=-1{Renvoie une erreur}

 end;

{-----------Fonction qui permet d'évaluer une opérateur--------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat
->Date:12.jul.2008
-----------------------------------------------------------------}
function EvalOperator(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var i:integer;opInfo:POperator;
type op=function(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
begin
 //showmessage('operator:'+eparr[epinfo.x]);
//New(opInfo);
 for i:=0 to (OperatorList.Count-1) do
 begin
         
         Opinfo:=Poperator(OperatorList[i]);
          //showmessage(Poperator(OperatorList[i]).name+'  '+eparr[epinfo.x]);
         // if Eparr[EpInfo.x]='echo' then          showmessage(Eparr[EpInfo.x+1);
         if string(opinfo.name)=trim(Eparr[EpInfo.x]) then
         begin
           EpInfo.traited:=true;

           //showmessage(Poperator(OperatorList[i]).name+'  '+eparr[epinfo.x]);
           {traitement des cmd
           if EpInfo.cmd<>-1 then begin
           case EpInfo.cmd of
           WorkAddition:
            begin
               if pos(Eparr[EpInfo.x],EpInfo.cArg1)>0 then
               EpInfo.x:=EpInfo.y+1
               else
               op(Opinfo.Pop)(EpInfo,Eparr,rinfo);
           end;
           end;
           end else op(Opinfo.Pop)(EpInfo,Eparr,rinfo);

           {fin du traitement des cmd}
           //showmessage(opinfo.name);
           op(Opinfo.Pop)(EpInfo,Eparr,rinfo);// enlever si cmd activé
           //if opInfo.name='&' then showmessage('bela opinffo');
           EpInfo.prev_traited:=pt_operator;
           break;
        end;
        // dispose(op);
 end;
   // if opInfo.name='echo' then   showmessage('last echo');
end;

{--------------Fonction qui permet d'évaluer une fonction ------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat
->Date:12.jul.2008    revision  16. 08.2010  09.9.2010
----------------------------------------------------------------}
function EvalFunction(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var
  finfo:pfunc;
  i:integer;
  found:integer; {recupère le retour de GetFunc}
  groupe,funcStr:string;
  SearchInfo:PFuncSearchInfo;
  paramInfo,dresult:PparamInfo;
  s_info,s_info2:pEpInfo;
  prev_groupe:pchar;
//  pend:integer;{indique la fin des argument des arguments de la fonction}
begin

  if (rinfo.rtype=vt_funcRef) then
     funcStr:=rinfo.reference
  else
     funcStr:=EParr[EpInfo.x];
  if (rinfo.rtype=vt_namespaceRef) then
      groupe:=rinfo.reference
  else
      groupe:=epinfo.group;
  //showmessage('function Eval: '+funcStr);
  new(finfo);
  fillfunc(finfo);
  new(searchInfo);
  searchInfo.ParamList:=Tlist.Create;
  searchInfo.DeclarationArgList:=Tlist.Create;

  found:=getfunc(EpInfo.PID,funcStr,groupe,finfo);
  if (found=0) then
  begin
    //showmessage('kjkjk');
    new(s_info);
    fillEpInfo(s_info);
    //s_info^:=epinfo^;
    epInfoCopy(s_info,epInfo);
    //inc(s_info.x);
    EvalArgs(searchInfo.ParamList,s_info,Eparr);
    //pend:=s_info.x;
   // showmessage(inttostr(searchinfo.ParamList.Count));
    if s_info.ErrId<>E_NONE then
    begin
       copyEpError(s_info,epinfo);
       EpInfo.traited:=true;
       exit;
    end;
    freefunc(finfo);
    new(finfo);
    fillfunc(finfo);
    Found:=getfuncEx(EpInfo.PID,funcStr,groupe,finfo,SearchInfo)
  end;
  if (found=0)then
  begin
      //showmessage('kjk');
    {calcul des valeurs par défaut des argument}
    for i:=0 to searchinfo.DeclarationArgList.Count-1 do
    begin
       paramInfo:=searchinfo.DeclarationArgList[i];
       if string(paramInfo.DefaultValue)>'' then
       begin
         new(dresult);
         new(s_info2);
         fillEpInfo(s_info2);
         s_info2.group:=E_STRING(finfo.groupe);
         fillrinfo(dresult);
         scr_evalEp(paramInfo.DefaultValue,dresult,false,s_info2,nil);
         if s_info2.ErrId<>E_NONE then
         begin
           EpInfo.Traited:=true;
           CopyEpError(s_info2,EpInfo);
           exit;
         end;
         placevalue(dresult,paraminfo,false);
         freeEpInfo(s_info2);
      end;
    end;
    {completion des argument entrée par les valeur par defaut des argument}
    for i:=searchinfo.ParamList.Count to searchInfo.DeclarationArgList.Count-1 do
    begin
      new(dresult);
      placevalue(Prinfo(searchInfo.DeclarationArgList[i]),dresult,false);
      searchinfo.ParamList.Add(dresult);
    end;
    {execution de la fonction}
      epinfo.traited:=true;
      if (Epinfo.prev_traited<>pt_none)  and (Epinfo.prev_traited<>pt_operator)then  {verifie que la colonne précédante est un opérateur}
      begin
      SignalError(EpInfo,EpInfo.x,E_PERSONAL,' Missing Semi column(;) after "'+Eparr[Epinfo.x-1]+'"');
      EpInfo.x:=EpInfo.x+1;
      exit;
      end;
      //showmessage(finfo.name);
      Prev_groupe:=EpInfo.group; EpInfo.group:=E_STRING(groupe);
      if finfo.ftype=ft_adress then
      call_afunc(finfo,searchinfo,EpInfo,Eparr,rinfo);
      if finfo.ftype=ft_virtual then
      call_vfunc(finfo,searchinfo,EpInfo,Eparr,rinfo);
      if finfo.ftype=ft_virtual2 then
      call_v2func(finfo,searchInfo,EpInfo,Eparr,rinfo);
      epinfo.traited:=true;
      StrDispose(EpInfo.group);
      EpInfo.group:=prev_groupe;
      EpInfo.prev_traited:=pt_function;
      epinfo.x:=s_info.x;
      freeEpInfo(s_info);

 

  end
  else
     case found of
     -1:;{aucune fonction trouvée}
     -2:
        begin
        SignalError(EpInfo,EPInfo.x,E_FUNCTION_ARG,'too much argument for this fonction');
        epInfo.traited:=true;
        end ;
     -3:
        begin
          SignalError(EpInfo,EPInfo.x,E_FUNCTION_ARG,'incompatible arguments for this fonction');
          epInfo.traited:=true;
        end;
     -4:
        begin
          SignalError(EpInfo,EPInfo.x,E_FUNCTIOn_ARG,'There no overload function that can accept these arguments');
          epInfo.traited:=true;
        end;
     -5:
        begin
          SignalError(Epinfo,Epinfo.x,E_Personal,'Unable to acces to this element. Access right is set to private');
          epInfo.traited:=true;
        end;
     end;

  // dispose(finfo);
   freefunc(finfo);
   searchInfo.DeclarationArgList.Free;
   searchInfo.ParamList.Free;
   dispose(searchInfo);   //libere

end;
{--------------Fonction qui permet d'évaluer une variable------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat
->Date:17.aout.2009     09 .09.2010
-----------------------------------------------------------------}
function Evalval(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var
   varInfo:PvarInfo;
   AlternativeVarDec:boolean; {lorque qu'on utilise "var"}
   access:TEvalAccess;
   found:integer;
   nsid:integer;
begin
   //showmessage('EvalConst:'+Eparr[EPInfo.x]);

  if (varlist=nil) then varlist:=Tlist.Create;
{  for i:=0 to (varList.Count-1) do
  begin
    New(varInfo);
    varInfo:=PvarInfo(varList[i]);

    if varInfo.name=Eparr[EpInfo.x] then
    begin
  }

    //showmessage(eparr[EpInfo.x]);
    new(varinfo);
    fillrinfo(varinfo);
    strcopy(varinfo.name,Pevchar(EParr[EpInfo.x]));
    varinfo.access:=epInfo.defaultMemberAccess;
    {ici on détecte automatiquement la declaration des variables}
    if (rinfo.isReference=true) and (rinfo.rtype<vt_namespaceRef) then
    begin
       varinfo.group:=E_STRING(epinfo.group);
       if (string(rinfo.reference)='public') or (string(rinfo.reference)='private') then
       varinfo.access:=rinfo.access;
       if rinfo.reference='typedef' then
       begin
         varinfo.rtype:=rinfo.rtype;
         //showmessage('reperage typedef');
         varinfo.access:=rinfo.access;
         
       end;

    end
    else
    if (rinfo.rtype=vt_namespaceRef) then
    begin
       nsid:=IndexFromNamespace(rinfo.reference,epInfo.PID);
       if nsid<>-1 then varinfo.access:=PscrInfo(namespacelist[nsid]).defaultMemberAccess;
       varinfo.group:=E_STRING(rinfo.reference);
       //showmessage(rinfo.name);
    end
    else
    begin
       nsid:=IndexFromNamespace(epInfo.group,epInfo.PID);
       if nsid<>-1 then
       begin
         varinfo.access:=PscrInfo(namespacelist[nsid]).defaultMemberAccess;
       end;
       
       varinfo.group:=E_STRING(EpInfo.group);
    end;
    access:=varinfo.access;

    if (rinfo.isReference) and ( string(rinfo.reference)='typedef') then  {ajout automatique}
    begin
       //varlist.add(varinfo);
       Setvar(Epinfo.PID,varinfo,true);
       //showmessage('type def auto add:'+varinfo.group);
    end;

    found:=getvar(EpInfo.PID,varinfo.name,varinfo.group,varinfo);
    if (found=0) then
    begin
        if (varinfo.access=aPrivate)  and (not(IsChildNamespace(EpInfo.PID,Epinfo.group,varinfo.group)))then  {verifie que la colonne précédante est un opérateur}
       begin
        SignalError(EpInfo,EpInfo.x,E_PERSONAL,'Can''t acces to a private variable');
        EpInfo.traited:=true;
        //EpInfo.x:=EpInfo.x+1;
        exit;
       end;
       //showmessage('evalval___'+varinfo.name+'___'+Eparr[EpInfo.x]);
       //if varinfo.rtype=vt_integer then showmessage('vt_integer');
       if (Epinfo.prev_traited=pt_const)  and (Epinfo.prev_traited=pt_variable)then  {verifie que la colonne précédante est un opérateur}
       begin
        SignalError(EpInfo,EpInfo.x,E_PERSONAL,' Missing Semi column(;) after "'+Eparr[Epinfo.x]+'"');
        EpInfo.x:=EpInfo.x+1;
        exit;
       end;

      //Showmessage('Evalconst:Find:'+Eparr[Epinfo.x]) ;
      //PlaceValue(varInfo,rinfo,true);
      if (high(Eparr)-EpInfo.x>=1) then
      begin
        if not(high(Eparr)-EpInfo.x>1) then
          rInfoCopy(rinfo,varinfo)  {AFECTATION VALEUR}
        else
        if (Eparr[EpInfo.x+1]='=') and (Eparr[EpInfo.x+2]<>'=')  then
        begin
          rinfo.rtype:=rt_pointer;
          rinfo.pt:=getvarAdress(EpInfo.PID,varinfo.name,varinfo.group);
        end
        else
        //if (Eparr[EpInfo.x+1]='[')  and (varinfo.rtype<>vt_dbdata) then
        if (Eparr[EpInfo.x+1]='[')  and (varinfo.rtype=vt_array) then
        begin
                // showmessage('array:'+varinfo.name);

          rinfo.rtype:=rt_pointer;
          rinfo.pt:=getvarAdress(EpInfo.PID,varinfo.name,varinfo.group);
        end
        else
        begin
         //rInfo^:=varInfo^;   {AFECTATION VALEUR}
         rInfoCopy(rinfo,varInfo);
        end;
      end
      else
      rInfocopy(rinfo,varinfo);
      //showmessage(rinfo.CharValue);
      //rInfo^:=varInfo^;  {AFECTATION VALEUR} {a revoir semble similaire avec la ligne d'en haut}
      //showmessage('rinfo:eval:'+varInfo.name+':'+ inttostr(varinfo.IntValue));
      if rinfo.rtype=vt_dbdata then
      begin
        //showmessage('is dbdata');
       // StrDispose(varInfo.CharValue);
       // dispose(varinfo);
       //showmessage(varinfo.name);
       // freerinfo(varinfo);
      end;
      if rinfo.rtype=vt_array then
      begin
        rinfo.pt:=getvarAdress(EPinfo.PID,varinfo.name,varinfo.group);
      end;
      {cas excepetionnel de reference a une fonction}
      if (rinfo.isReference) and (rinfo.rtype=vt_funcRef) then
      begin
        Evalfunction(EpInfo,EParr,rinfo);
        exit;
      end;
      EpInfo.Traited:=true;
      EpInfo.prev_traited:=pt_variable;

      //EpInfo.x:=EpInfo.x+1;
      //showmessage(eparr[epinfo.x]);
    //break;
       //   if varinfo.name='bela' then showmessage(rinfo.name+'____');
    freerinfo(varinfo);
  end
  else
  if found=-5 then  {signal access rigths error}
  begin
       SignalError(Epinfo,Epinfo.x,E_Personal,'Unable to acces to this element. Access right is set to private');
       EpInfo.traited:=true;
       EpInfo.prev_traited:=pt_variable;
       freerinfo(varinfo);
  end
  else
  begin
    {auto declare variable if preceded by var or $}
    if (epInfo.x>0) then
    begin
       if (eparr[epInfo.x-1]='var') or (eparr[epInfo.x-1]='$')  then
       begin
         varInfo.rtype:=vt_null;
         //varinfo.group:=epinfo.group;
        // showmessage(varinfo.group);
         varinfo.heritedNameSpace:=E_STRING(varInfo.group);
         varinfo.access:=access;
         //varlist.Add(varInfo);
         Setvar(EpInfo.PID,varinfo,true);

         rinfo.rtype:=rt_pointer;
         rinfo.pt:=varinfo;   {retour un pointeur sur la nouvelle variable}

         EpInfo.Traited:=true;
         EpInfo.prev_traited:=pt_variable;
       end
       else
       if (high(Eparr)-EpInfo.x>1 ) then
       {au cas ou on a par exemple a=5. on déclare la variable automatiquement avant que EqualOp ne comment son traitement: meme code qu'en dessous}
       if (Eparr[EpInfo.x+1]='=') and (Eparr[EpInfo.x+2]<>'=')  then
       begin
         varInfo.rtype:=vt_null;
         varinfo.heritedNameSpace:=E_STRING(varInfo.group);
         varinfo.access:=access;
         Setvar(EpInfo.PID,varinfo,true);
         rinfo.rtype:=rt_pointer;
         rinfo.pt:=varinfo;   {retour un pointeur sur la nouvelle variable}
         EpInfo.Traited:=true;
         EpInfo.prev_traited:=pt_variable;
       end;

    end
    else
    {au cas ou on a par exemple a=5. on déclare la variable automatiquement avant que EqualOp ne comment son traitement}
    if (high(Eparr)-EpInfo.x>1 ) then
    if   (Eparr[EpInfo.x+1]='=') and (Eparr[EpInfo.x+2]<>'=')  then
    begin
       // showmessage('new var');
        varInfo.rtype:=vt_null;
        //varinfo.group:=E_STRING(epinfo.group);
        varinfo.heritedNameSpace:=E_STRING(varInfo.group);


        varinfo.access:=access;
        //varlist.Add(varInfo);
        Setvar(EpInfo.PID,varinfo,true);

        //rinfo.rtype:=vt_null;
        if (Eparr[EpInfo.x+2]='=')  then
          rInfoCopy(rinfo,varinfo)
        else
        begin
          rinfo.rtype:=rt_pointer;
          rinfo.pt:=varinfo;
        end;
        EpInfo.Traited:=true;
        EpInfo.prev_traited:=pt_variable;
        //showmessage(Eparr[epinfo.x]);
       // EpInfo.x:=EpInfo.x+1;
        //inc(epInfo.x);
    end
    else
    if   (Eparr[EpInfo.x+1]='[') then
    {au cas c'est la un tableau non defini que l'utilisateur veut exploiter}
    begin
        varInfo.rtype:=vt_array;
        varinfo.heritedNameSpace:=E_STRING(varInfo.group);
        varinfo.access:=access;
        //showmessage('new array var');
        //varinfo.group:=epinfo.group;
        //varlist.Add(varInfo);
        Setvar(EpInfo.PID,varinfo,true);
        rinfo.isReference:=true;
        rinfo.rtype:=rt_pointer;
        rinfo.pt:=varinfo;
        //EpInfo.x:=EpInfo.x+1;
        EpInfo.Traited:=true;
        EpInfo.prev_traited:=pt_variable;
       // showmessage('jjk_ auto create new array:'+varinfo.name)
    end;
    if not EpInfo.Traited then  {Dernière solution lorsque varinfo n'est pas traité}
    begin
      freerinfo(varinfo);
    end;

  end;



end;


{--------------Fonction qui permet d'évaluer une constante------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat
->Date:16.jul.2008
----------------------------------------------------------------}
function EvalConst(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var
  Constinfo:PconstInfo;i:integer;
  sPrevTraited:TpreviewTraited;
begin
  //showmessage('EvalConst:'+Eparr[EPInfo.x]);
  for i:=0 to (constList.Count-1) do
  begin
    //New(ConstInfo);
    ConstInfo:=PconstInfo(ConstList[i]);
    if string(ConstInfo.name)=Eparr[EpInfo.x] then
    begin
    //Showmessage('Evalconst:Find:'+Eparr[Epinfo.x]) ;
    PlaceValue(constInfo.rInfo,rinfo,true);
    rInfo.rtype:=constInfo.rInfo.rtype;
    EpInfo.Traited:=true;
    EpInfo.prev_traited:=pt_const;
    break;
    end;
  end;
  {17.aout 2009 :-- permet d'évaluer les variable}
  if (not(Epinfo.traited )) then
  begin
    sPrevTraited:=epinfo.prev_traited;
    Evalval(EpInfo,Eparr,rinfo) ;
    {23 mai 2011:--verifier la synthax: evite de faire suivre 2 variables sans operateurs}
    if (EpInfo.traited) and(sPrevtraited=Pt_variable) then
    if (rinfo.rtype=vt_char)   or (rinfo.rtype=vt_numeric) or (rinfo.rtype=vt_integer)
     or(rinfo.rtype=vt_bool) or (rinfo.rtype=vt_float)   or (rinfo.rtype=vt_null)   then
    begin
      SignalError(EpInfo,EpInfo.x,E_PERSONAL,' Missing Semi column(;) after "'+Eparr[Epinfo.x-1]+'"');
    end;

  end;


end;

{--------------Fonction qui permet d'évaluer un extrat------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat
->Date:12.aout.2008
----------------------------------------------------------------}
function EvalExtra(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var
  Numstr:string;
  x:integer;
begin
   x:=epinfo.x;
   {Traitement de la date}
   if isdate(Eparr,epinfo.x) then
   begin
   EpInfo.traited:=true;
   EpInfo.prev_traited:=pt_const;
   rinfo.floatvalue:=strtodate(Eparr[x]+Eparr[x+1]+Eparr[x+2]+Eparr[x+3]+Eparr[x+4]);
   rinfo.rtype:=vt_date;
   Epinfo.x:=Epinfo.x+4
   end;
   {Traitement du numeric}
   //showmessage(inttostr(EpInfo.x ));
   if isnumeric(Eparr[EpInfo.x]) and (not EpInfo.traited) then
   begin
       //showmessage(inttostr(EpInfo.x )+' numeric__'+Eparr[EpInfo.x]+'___'+inttostr(length(Eparr[EpInfo.x])));
       EpInfo.traited:=true;
       EpInfo.prev_traited:=pt_const; //showmessage('hjhj');
       rinfo.rtype:=vt_integer;
       if (EpInfo.x+1<=high(eparr)) then
       begin
       DecimalSeparator:='.' ;
       if (Eparr[EpInfo.x+1]='.') and (isnumeric(Eparr[EpInfo.x+2])) then
       begin
         NumStr:=format('%s.%s',[Eparr[EpInfo.x],Eparr[EpInfo.x+2]]);
         EpInfo.x:=EpInfo.x+2;
         rinfo.rtype:=vt_float;
       end else
       NumStr:=Eparr[EpInfo.x];
       end else
       NumStr:=Eparr[EpInfo.x];
       rinfo.floatvalue:=strtofloat(numstr);
       rinfo.IntValue:={rinfo.IntValue+}round(rinfo.floatvalue);
       //showmessage('numeric'+numstr);
    end
    else
    {Traitement du texte, utilise l'operateur selstr(plus rapide)  }
    if (Eparr[x]='"')  or (Eparr[x]='''')then
    begin
    EpInfo.traited:=true;
    //showmessage('str extraction');
    selstr(epinfo,eparr,rinfo);
    //showmessage('str render');
    EpInfo.prev_traited:=pt_const;
    end
    else
    {traitement des variables}
    if (lowerCase(Eparr[x])='var')  or (Eparr[x]='$') then
    begin
      inc(epinfo.x) ;
      result:=evalVal(EpInfo,Eparr,rinfo);
    end;
end;

{Fonction qui permet de copier une valeur d'un PrInfo à un PrInfo}
function PlaceValue(initr,endr:Prinfo;Move:boolean):integer;
begin

    case initr.rtype of
    vt_integer:
    begin
       if move then endr.IntValue:=initr.IntValue
       else endr.IntValue:=endr.IntValue+initr.IntValue;
    end;
    vt_float:
    begin
       if move then endr.floatvalue :=initr.floatvalue
       else endr.floatvalue:=endr.IntValue+initr.floatvalue;
    end;
    vt_char:
    begin
       if move then
       StrCopy(endr.CharValue,initr.CharValue)
       else
       StrCat(endr.CharValue,initr.CharValue);
    end;
    vt_bool:
    begin
      endr.BoolValue:=initr.BoolValue;
    end;

    end;

end;


{Fonction qui permet d'exécuter un commande  eval contenu dans epinfo
->Date:29.07.2008}
function ExEpcmd(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
const rbreak=1;
begin
 result:=0;
 case EpInfo.cmd of
 WorkAddition:
       begin
       if pos(Eparr[EpInfo.x],EpInfo.cArg1)>0 then
       result:=rbreak
       end;
 workUntilType:{10/16/2012}
       begin
       if (rinfo.rtype=EpInfo.cArg2)  then
         result:=rbreak;
       if (EpInfo.cArg2=vt_numeric) and ((rinfo.rtype=vt_integer) or (rinfo.rtype=vt_float)) then
         result:=rbreak;

       end;
 workUntil:{continu j'usqua rencontré le mot spécifié}
       begin
       strLcopy(Epinfo.BreakChar,EpInfo.cArg1,strlen(EpInfo.BreakChar)+1);
       Epinfo.cmd:=worknone;
       end;
 workabort:
      begin
        result:=rbreak;
        //showmessage('work abort');
      end;
 work_SWITCH:
      begin
      EpInfo.traited:=(trim(lowercase(Eparr[EpInfo.x]))<>'case')
        
      end;
 work_SETPREVIEWTRAITED:
      begin
      EpInfo.prev_traited:=TPreviewTraited(EpInfo.carg2);
      end;
 end;
end;

{--------fonction racine de l'évaluateur d'expression--------------
EPInfo:Information sur le processus d'évaluation
Eparr:Tableau des expression
rinfo:information sur le résultat

NB: evalue le tableau d'expresssion jusqu'à ce que epinfo.x>y
donc à la fin de l'évaluation, (epinfo.x=epinfo.y+1 par défaut)
NB2:pour recuperer l'endroit ou s'est arrété l'évaluation après son arrêt, on fait(EpInfo.x-1) car
EpInfo.x s'incrémente avant  la fin pour qu'on remarque que epInfo.x>epInfo.y
( voir while not (Epinfo.x>EpInfo.y) do et en bas epinfo.x:=epInfo.x+1)
Date:12.jul.2008
modifier:12.aout.2008; 27.aout.2009(ajout commentaire)
------------------------------------------------------------------}
function OperateInt(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;

begin
  {Initialisation des variables}
  if epInfo.x=-1 then EPInfo.x:=0;
  if epInfo.y=-1 then epinfo.y:=high(Eparr);
  //showmessage(eparr[1]+'___'+inttostr(epinfo.y));
  {indique qu'il n'ya pas d"erreur}
  if rinfo=nil then showmessage('rinfo is nil');
  //showmessage(rinfo.CharValue);
  rinfo.ErrId:=E_none;
  EpInfo.ErrId:=E_none;
  result:=0;
  {indique qu'il n'y a pas de colonne précédante }
  EpInfo.prev_traited:=pt_none;
 // showmessage('in'+inttostr(epinfo.x)+'in'+inttostr(epinfo.y));
  EpInfo.ErrDeclationMode:=errNormal;{pour la couche script: desactive par defaut la déclaration alternative des erreurs}
  {Processus}
  while not (Epinfo.x>EpInfo.y) do
  begin
    EPInfo.Traited:=false;
    {Verification de la plage x et y}
    if  (EpInfo.x>high(eparr)) or (epinfo.x>high(eparr)) then
    begin
    showmessage('x depasse y');
    EpInfo.ErrId:=E_syntax;
    EpInfo.Traited:=true;
    end;
     {traitement des cmd}
     if EpInfo.cmd<>-1 then
     begin
     if ExEpcmd(Epinfo,Eparr,rinfo)=1{rbreak} then
     break;
     end;
     {verifie qu'il n'y a pas un breakchar}
     if (EpInfo.BreakChar<>'') and (Eparr[EpInfo.x]=EpInfo.breakchar) then
     break;
    {Traitement extra  comme numeric and date}
    if not  epinfo.traited then
    EvalExtra(EpInfo,Eparr,rinfo);
    {Traitement operateurs, function, constantes}
    if not EpInfo.Traited then
    EvalOperator(EpInfo,Eparr,rinfo);
    if not EpInfo.traited then
    evalfunction(EpInfo,Eparr,rInfo);
    if not EPInfo.traited then
    evalconst(EpInfo,Eparr,rInfo);
    if not EPInfo.traited then {08 08 2010}
    evalNamespaceRef(EpInfo,Eparr,rInfo);
    {s'il n'arrive pas declanche une erreur}
    if epinfo=nil then showmessage('Nil epinfo: erreur interne');
    if (not Epinfo.traited) then  {S'il le caractère n'est pas reconnu}
       if (length(trim(eparr[EpInfo.x]))>0) then
       begin
       //showmessage('jkj');
       Epinfo.ErrId:=E_UnknowSymbol;
       EpInfo.errPos:=EpInfo.x;
       end;
    If EpInfo.ErrId<>E_None then
    begin
      if not EpInfo.traited then
      begin
      //Showmessage('error  '+ eparr[epinfo.x]);  {activer si pour programmer}
      end;
      //showmessage('error'+epinfo.ErrParams);
      ManageError(Epinfo,Eparr,rinfo);
      Result:=1;
      break
    end;
    EpInfo.x:=EpInfo.x+1;
  end;
 result:=0;
end;

{fonction qui convertit un type en string en un type reconnu }
function StrTortype(str:string):integer;
begin
  if str='int' then result:=vt_integer
  else
  if str='integer' then result:=vt_integer
  else
  if str='float' then result:=vt_float
  else
  if str='double' then result:=vt_float
  else
  if str='char' then result:=vt_char
  else
  if str='string' then result:=vt_char
  else
  if str='bool' then result:=vt_bool
  else
  if str='boolean' then result:=vt_bool
  else
  if str='date'  then result:=vt_date
  else
  if str='array' then result:=vt_array
  else
  if str='namespaceRef' then result:=vt_namespaceRef;
end;
{fonction qui convertit un type en string en un type reconnu (AVANCE }
function StrTortypeEx(PID:integer;str:string;rinfo:prinfo;const group:string=''):integer;
var
  str2:string;
  i:integer;
begin
  if str='int' then rinfo.rtype:=vt_integer
  else
  if str='integer' then rinfo.rtype:=vt_integer
  else
  if str='float' then rinfo.rtype:=vt_float
  else
  if str='char' then rinfo.rtype:=vt_char
  else
  if str='string' then rinfo.rtype:=vt_char
  else
  if str='bool' then rinfo.rtype:=vt_bool
  else
  if str='boolean' then rinfo.rtype:=vt_bool
  else
  if str='date'  then rinfo.rtype:=vt_date
  else
  if str='array' then rinfo.rtype:=vt_array
  else
  if str='namespaceRef' then rinfo.rtype:=vt_namespaceRef
  else
  begin
    i:=Find_hNamespace(PID,str,group);
    if i<>-1 then
    begin
       rinfo.rtype:=vt_namespaceRef;
       rinfo.isReference:=true;
       rinfo.reference:=E_STRING(PscrInfo(namespacelist[i]).Name);
    end;
  end;
end;
{fonction qui convertit un type reconnu en un type en string  }
function rtypeToStr(rtype:integer):string;
begin
  case rtype of
  vt_integer:
       result:='int';
  vt_float:
       result:='float';
  vt_char:
       result:='char';
  vt_bool:
       result:='bool' ;
  vt_date:
       result:='date';
  vt_none:
       result:='void';
  vt_null:
       result:='null';
  vt_array:
       result:='array';
  vt_classtype:
       result:='class';
  else
       result:='unknow';
  end;
end;

function rtypeToStrEx(rinfo:Prinfo):string;
begin
  case rinfo.rtype of
  vt_integer:
       result:='int';
  vt_float:
       result:='float';
  vt_char:
       result:='char';
  vt_bool:
       result:='bool' ;
  vt_date:
       result:='date';
  vt_none:
       result:='void';
  vt_null:
       result:='null';
  vt_array:
       result:='array';
  vt_classtype:
       result:=rinfo.rtypeStr;
  vt_namespaceRef:
       begin
          result:=rinfo.reference;
       end;
  else
       result:='unknow';
  end;
end;

{FOnction qui permet d'évaluer les paramètres d'une fonction à l'interierur d'une expression
revision importante:31.08.2010 la fonction EvalArgs se contente d'évaluer les arguments mais ne
compare pas les arguments de l'utilisateur a l'argument exigé par la fonction}
function EvalArgs(ParamList:Tlist;EpInfo:PepInfo;Eparr:strarr):integer;
var
  Param:PparamInfo;Pend,i:integer;s_inf:PepInfo;
Begin

  if (High(EParr)-EpInfo.x)>0 then
  if Eparr[EpInfo.x+1]<>'(' then
  begin
      exit;
  end;
  Pend:=GetParaEnd(Eparr,EpInfo.x); 
  New(s_inf);
  fillEpInfo(s_inf);
  //s_inf^:=EpInfo^;
  EpInfoCopy(s_inf,EpInfo);
  EpInfo.y:=Pend-1;
  EpInfo.x:=EpInfo.x+2;
  //showmessage('EvalArgs:Paramcount:'+inttostr(paramList.Count));
  result:=0; {Revision importante 25.08.2008}
  //showmessage(eparr[epinfo.y] );
  
  while not (EpInfo.x>EpInfo.y) do
  begin
    result:=0;
    //Showmessage(inttostr(epinfo.x)+' ___y'+inttostr(epinfo.y));
    (*if (EpInfo.x>EpInfo.y)  then  {Si x depasse la parenthèse}
    begin
      Showmessage('Erreur du nombre d''argument');
      SignalError(EpInfo,S_inf.x,E_NoAllArgs,'');
      result:=1;
      Break;
    end else *)
    Begin
      {evalue jusqu'a rencontré un ',' }
      New(Param);
      // Param^:=pparamInfo(ParamList[i])^;
      fillrinfo(param);
      EpInfo.cmd:=workuntil ;
      EpInfo.cArg1:=',';
      OperateInt(EpInfo,EPArr,Param);
      if EpInfo.ErrId<>E_NONE then break;
      Inc(EpInfo.x);{puisque x s'arrete à ','}
      ParamList.Add(Param);
    end;

  end;

  //if EPInfo.ErrId<>E_none then   showmessage('erreur on args');
  EpInfo.y:=s_inf.y;
  EpInfo.x:=pend;
  //showmessage(eparr[EpInfo.x-1]+'  epinfo x'+inttostr(Epinfo.x)+' epinfo y'+inttostr(EpInfo.y));

  if paramlist.Count=0 then  {Au ca ou il yaurait pas de paramètres 25.08.2008 corrigé le 23.mai.2011}
  begin
    if (high(Eparr)-s_inf.x)=0 then
      EpInfo.x:=s_inf.x+1
    else
    if ((high(Eparr)-s_inf.x)>0) then
      if (Eparr[s_inf.x+1]='(') then  EpInfo.x:=s_inf.x+2  else EpInfo.x:=s_inf.x+1;

  end;
  //showmessage(eparr[epinfo.x]);
  EpInfo.cmd:=worknone;
  EpInfo.BreakChar:='';
  freeEpInfo(s_inf);
    

end;

{Fonction qui permet d'avoir des informations sur les arguments d'une fonction}
function GetArgInfo(PID:integer;finfo:Pfunc;ArgList:Tlist):integer;
var
  gar3,gar2,gar:strarr;ParamInfo:pParamInfo; i:integer;
  ArgStr:string;
  s_info:pEpInfo;
  dresult:prinfo;
begin
  gar:=Getdecompose(finfo.params,',',false);
  //showmessage(finfo.params);
  for i:=0 to high(gar) do
  begin
    New(ParamInfo);
    {gar2:=Getdecompose(gar[i],':',false);
    ParamInfo.pname:=gar2[0];
    ParamInfo.ptype:=Strtortype(gar2[1]);
    New(paramInfo.rinfo);
    paramInfo.rinfo.CharValue:=stralloc(255);
    paramInfo.rinfo.IntValue:=0;
    fillrinfo(paraminfo.rinfo);
    ArgList.Add(ParamInfo)
    }
    fillrinfo(paraminfo);
    gar2:=Getdecompose(gar[i],'=',false);
    argStr:=gar2[0];
    if Length(gar2)=2 then
      paramInfo.DefaultValue:=E_STRING(gar2[1]);
    gar3:=Getdecompose(ArgStr,':',false);  {declaration de type "ab:int"}
    strcopy(ParamInfo.name,Pevchar(gar3[0]));
    //showmessage('argstr:'+argstr);
    if Length(gar3)=2 then
    begin
        //showmessage(gar3[1]);
       StrtortypeEx(PID,gar3[1],paraminfo,finfo.groupe);
    end
    else
    begin
       gar3:=Getdecompose(ArgStr,' ',false) ; {declaration de type "int ab"}
       if Length(gar3)=2 then
       begin
         strcopy(ParamInfo.name,Pevchar(gar3[1]));
         StrtortypeEx(PID,gar3[0],paramInfo,finfo.groupe);
       end
       else
       begin
         strcopy(ParamInfo.name,PevChar(gar3[0]));
         paramInfo.rtype:=vt_none;
       end;

    end;

    ArgList.Add(ParamInfo)

  end;
end;
{fonction qui permet d'appeler une fonction de type adressage
les fonction de l'évaluateur d'expression sont de type sdtcall
donc ca lit les argument de droite à gauche.
alors il faut passer les arguments du dernier au premier
->le paramètre args designe les argument deja evalués}
function Call_afunc(func:Pfunc;args:PfuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;
var
  //ParamList:TList;
  Param:PparamInfo;
  i,Intval:integer;
  StrVal:Pchar;
  BoolVal:Boolean;
  floatVal:double;
  funcAdr:Pointer;
  a:integer;
  SearchInfo:PFuncSearchInfo;


begin
  searchInfo:=args;
  if args=nil then
  begin
     new(SearchInfo);
     SearchInfo.DeclarationArgList:=Tlist.Create;
     SearchInfo.ParamList:=Tlist.Create;

     //ParamList:=TList.Create;
     GetArgInfo(EpInfo.PID,func,SearchInfo.DeclarationArgList);

      if EvalArgs(SearchInfo.paramList,EpInfo,EParr)=0 then exit;
  end;

begin;

  //strval:=stralloc(255);
  //showmessage('Call_afunc:'+func.name);
  for  i:=0 to searchInfo.declarationArglist.count-1 do {01.05.2011 evite de confondre les type surtout quand il s'agit de integer et float}
  begin
    PParamInfo(searchInfo.paramlist[i]).rtype:= Prinfo(searchInfo.declarationArglist[i]).rtype;
  end;

  i:=SearchInfo.ParamList.Count-1;
  {transfert des paramètres de la function}
  while not i<0 do
  begin
    //showmessage('kjk:'+Prinfo(searchInfo.declarationArglist[i]).name+' rtype:'+inttostr(Prinfo(searchInfo.declarationArglist[i]).rtype));
    New(Param);
    fillrinfo(param);
    //Param^:=PParamInfo(SearchInfo.ParamList[i])^; {AFFECTATIOn DE VALEUR}
    rInfoCopy(Param,PParamInfo(SearchInfo.ParamList[i]));
    if param.rtype=vt_integer then
    begin
    Intval:=Param.IntValue;
   // showmessage('Call_afunc:intval:'+inttostr(intval));
    asm
    mov Eax,intval
    Push Eax
    end
    end;
    If (param.rtype=vt_char) then
    begin
    //New(strVal);
    StrVal:=Param.CharValue;
    //showmessage('Call_afunc:strval:'+strval);
    asm
    mov Eax,strval
    Push Eax
    end
    end;
    If (param.rtype=vt_namespaceRef) then
    begin
    //New(strVal);
    StrVal:=pchar(Param.reference);
    //showmessage('Call_afunc:strval:'+strval);
    asm
    mov Eax,strval
    Push Eax
    end
    end;
    if param.rtype=vt_array then
    begin
      intval:=integer(param);
      asm
      mov Eax,intval
      Push Eax
      end
    end;
    If param.rtype=vt_bool then
    begin
       if Param.BoolValue then
       begin
       //showmessage('Call_afunc:Boolval:vrai');
       asm Push $01 end
       end else
       begin
       //showmessage('Call_afunc:Boolval:faux');
       asm push $00 end
       end;
    end;
    if (param.rtype=vt_float) or (param.rtype=vt_date) then
    begin
        floatval:=param.floatvalue;
        asm
        push dword ptr floatval[4]
        push dword ptr floatval
        end
    end;
  dec(i);
  end;
  //SearchInfo.Paramlist.free;
  funcAdr:=func.pfunc;
  rinfo.rtype:=func.rtype;
   {Appel de la function et transfers des resultats rétournés par la fonction dans rinfo}
  case func.rtype of
  vt_float:
  begin
    asm
    //fld  funcAdr
    call funcAdr
   
    fstp  floatval


    end;
    //showmessage('float result:'+floattostr(floatval2));
    rinfo.floatvalue:=floatval;
    rinfo.IntValue:=round(floatval);
   // rinfo.rtype:=vt_float;
  end;
  vt_date:
  begin
    asm
    call funcAdr
    fstp floatval
    end;
    showmessage('float result:'+floattostr(floatval));
    rinfo.floatvalue:=floatval;
  end;
  vt_integer:
  begin

   asm
   call funcAdr
   mov intval,EAX
   end;
    //showmessage('integer result:'+inttostr(intval));
    rinfo.IntValue:=intval;
    rinfo.floatvalue:=intval;
  end;
  vt_namespaceRef:{21 avril: permet aux fonctions passer des references à des namespace}
  begin

    strval:=stralloc(256);
    asm
    call funcAdr
    mov strval,EAX
    end;
    //showmessage('string result:'+ pchar(strval));
    strlcopy(rinfo.CharValue,strval,256);
    rinfo.reference:=E_STRING(rinfo.CharValue);
    rinfo.isReference:=true;
    //rinfo.reference:=dresult.reference;
    rinfo.rtype:=vt_namespaceRef;
  end;
  vt_char:
  begin
    //strval:=stralloc(256);
    asm
    call funcAdr
    mov strval,EAX
    end;
    //showmessage('string result:'+ strval);
    if strval<>nil then
    strlcopy(rinfo.CharValue,strval,StrBufSize(strval));
    //Strdispose(strval);
    //if pos('6',string(strval))>0 then showmessage('bad request');  {bad just for test}
    rinfo.IntValue:=56;
  end;
  vt_bool:
  begin
    asm
    call funcAdr
    mov  intval,eax
    end;
    {if boolean(intval)then
    showmessage('bool result:vrai')
    else showmessage('bool result:faux') ;
    }
    rinfo.BoolValue:=boolean(intval);
  end;
  vt_none: {revision importante permet de supporter les procedures 25.08.2008}
  begin
    asm
    call funcAdr
    end;
  end;
  vt_array,rt_Prinfo:
  begin
     asm
     call funcAdr
     mov  intval,eax
     end;
     rinfo^:=Prinfo(intval)^;  {a revoir pour faire l'affectation avec des pointers}
  end;
  rt_pointer:
  begin
     asm
     call funcAdr
     mov  intval,eax
     end;
     rinfo.pt:=Pointer(intval);
     rinfo.rtype:=rt_pointer;
  end;

  end;
  {Mov i, EAX    }
  //showmessage(inttostr(i));
  //showmessage(inttostr(epinfo.x)+ '___' +inttostr(epinfo.y));
  for i:=0 to searchInfo.ParamList.Count-1  do freerinfo(Prinfo(searchInfo.ParamList[i]));
  for i:=0 to searchInfo.DeclarationArgList.Count-1  do freerInfo(prinfo(searchInfo.DeclarationArgList[i]));
  if args=nil then
  begin
    SearchInfo.Paramlist.free;SearchInfo.DeclarationArgList.free;
  end;

end;
end;



{Fonction qui permet de modifier le cmd de epinfo}
function Changecmd(Epinfo:Pepinfo;NewCmd:integer;arg1:string;arg2:integer):integer;
var str:string;
begin
  if (Newcmd=workaddition)then
  if (Epinfo.cmd=workaddition) and (EpInfo.cArg2=Cpermanent) then
  str:=arg1+EpInfo.cArg1;
  
  EpInfo.cmd:=NewCmd;
  strcopy(EpInfo.cArg1,pchar(str));
  EpInfo.cArg2:=arg2;

end;
{Fonction qui permet de restaurer un epinfo
ne modifie pas les x et y }
function restoreEpInfo(sEpInfo,nEpInfo:pepInfo):integer;
var x,y:integer;
begin
x:=nepInfo.x;
y:=nepinfo.y;
nepinfo.cmd:=sepinfo.cmd;
nepinfo.cArg1:=sepinfo.cArg1;
nepinfo.BreakChar:=sepinfo.BreakChar;
nepinfo.ForUser:=sepinfo.ForUser;
nepinfo.ErrId:=sepinfo.ErrId;
nepinfo.ListRootStr:=sepinfo.ListRootStr;
nepinfo.cArg2:=sepinfo.cArg2
end;

function SaveEpInfo(EpInfo,sEpInfo:pepinfo):integer;
begin
  //sepinfo^:=epinfo^
  epInfoCopy(SepInfo,EpInfo);
end;

{Fonction qui permet de signaler une erreur
-Date:29.07.2008}
function SignalError(EpInfo:Pepinfo;ErrPos,ErrId:integer;ErrParams:string;DeclarationMode:TErrorDeclarationMode=errNormal):integer;
begin
  EpInfo.ErrId:=ErrId;
  EpInfo.ErrPos:=ErrPos;
  if assigned(EpInfo.ErrParams) then strDispose(EpInfo.ErrParams);
  EpInfo.ErrParams:=E_STRING(ErrParams);
  EpInfo.ErrDeclationMode:=DeclarationMode;
end;

{fonction qui donne des information sur l'erreur à l'application hote
portion tirée de EP_errdlg
28.04.2011}
function  ShowEpError(EpInfo:PEpInfo;Eparr:Strarr;Errmsg:string):integer;
var
    i,gpos:integer;
    str:string;
begin
  For i:=0 to high(Eparr) do
  begin
    if i=EpInfo.ErrPos then  gpos:=length(str) ;
    str:=str+Eparr[i];
  end;
  ShowEpErrorDlg(pchar(str),length(str)+1,gpos,pchar(Errmsg));
end;

{Fonction de gestion des erreurs dans EpEval
->Date:29.07.2008}
function  ManageError(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;

var
  ErrMsg,str:string;
  i:integer;
begin
  If (not (EpInfo.ErrDeclationMode=ErrAlternative)) then
  Case EpInfo.ErrId of
  E_NoAllArgs:
           Errmsg:=format('la function "%s" nécessite plus de parametres',[Eparr[Epinfo.ErrPos]]);
  E_NoCharEnd:
           Errmsg:='la chaine n''a pas de fin';
  E_NoParaEnd:
           Errmsg:='La parenthèse n''a pas de fin';
  E_unKnowSymbol:
           begin
           //showmessage(EpInfo.group+'__'+ inttostr(EpInfo.errPos)) ;
           Errmsg:=format('Erreur de syntaxe: Symbole ou caractère "%s"  non declaré / inconnu.',[Eparr[Epinfo.ErrPos]]);

           end;
  E_Syntax:Errmsg:='Erreur de syntaxe';

  E_DivError:
           Errmsg:='Impossible de diviser un nombre par 0';
  E_Operror:
           Errmsg:='Operateur nom applicable pour ce type de calcul';
  E_Incompatible:
           Errmsg:='Type incompatible';
  E_SWITCH_SYNTHAX:
           Errmsg:=' La syntaxe de la fonction switch non respectée: "{" attendu mais "token" trouvé';
  E_SWITHC_ARG_TYPE:
           Errmsg:=' Le type de l''argument de  switch n''est pas supportée!';
  E_UNAPPROPRIETED_USEOFBREAK:
           Errmsg:='utilisation inappropriée de la fonction break';
  E_CASE_TYPE_INVALID:
           Errmsg:='l''argument de case n''est de même type que l''argument de switch';
  E_CASE_SYNTHAX:
           Errmsg:='utilisation inapproprié de "case" cet operateur doit être utilisé dans dans une structure "switch"';
  E_REPEAT_SYNTHAX:
           Errmsg:='Erreur de synthax pour l''operateur "do" while attendu ' ;
  E_REPEAT_WHILE_SYNTHAX:
           Errmsg:='Erreur. l''argument de while précédé de "do" doit être de type boolean';
  E_TRY_SYNTHAX:
           Errmsg:='try<instructions bloc> doit ête suivi de l''operateur catch  or finaly';
  E_TRY_CATCH_SYNTHAX:
           Errmsg:='catch<instructions bloc> doit être précédé de try<instructions bloc>';
  E_TRY_FINALY_SYNTHAX:
           Errmsg:='finaly<instructions bloc> doit être précédé de try<instructions bloc>';
  E_Extra:
         begin
         if assigned(epinfo.ErrParams) then LoadErrInfo(EpInfo.ErrParams);
         end;
  else   begin
         if assigned(epInfo.ErrParams) then Errmsg:=EpInfo.ErrParams;
         //showmessage('hjhj');
         end;

  end;
  
  for i:=0 to high(Eparr) do begin
  str:=str+EParr[i];
  end;
  if assigned(epInfo.ErrParams) then
  begin
     if (errmsg<>EpInfo.ErrParams) and (EpInfo.ErrParams<>'') then
     errmsg:=errmsg+'['+EpInfo.ErrParams+']';
  end;

  if not EpInfo.silentMode then
  ShowEpError(EpInfo,Eparr,Errmsg) ;

  {If ((EpInfo.scr_scr<>nil) and(not EpInfo.AlternativeErrorDeclaration)) then
  begin
  EpInfo.ErrParams:=Errmsg;
  end;  }
  If (not (EpInfo.ErrDeclationMode=errAlternative)) then
  begin
  EpInfo.ErrParams:=E_STRING(Errmsg);

  end;
  //if EpInfo.AlternativeErrorDeclaration then  showmessage('noalternative');

end;

{Fonction qui permet de précompiler une expression( remplace les
champs virtuelles par leurs expressions}{a revoir}
function Precompile(EpInfo:pepinfo;Eparr:strarr):string;
var
  str,mo:string;
  //field:pvfield;
  i:integer;
begin
 (* i:=EpInfo.x;
  Epinfo.x:=0;
 {for i:=0 to High(eparr) do
   begin
     mo:=eparr[i];     showmsg(pchar('part:'+mo+'dfd'));
   end; }
  while not (epinfo.x>high(eparr)) do
  begin

    if   Eparr[EpInfo.x]='#%%%^$space%%%%%%%%%%%%%%%%%####' then  Eparr[EpInfo.x]:=' ';
    new(field);
    if findvfield(eparr[epinfo.x],field)then
    begin
    //showmessage('Virtual Field: '+eparr[epinfo.x]);
    {Verifie si il ya un point derriere expemple:[char:inscript.nationalite]'}
    if (EpInfo.x-1)<0 then
    str:=str+GetvFieldEp(field,Epinfo,Eparr)
    else
    if (Eparr[EpInfo.x-1]<>'.')  then
    str:=str+GetvFieldEp(field,Epinfo,Eparr)
    else
    str:=str+Eparr[EpInfo.x];
    end else
    str:=str+Eparr[EpInfo.x];    //showmessage('ddf'+Eparr[EpInfo.x]+'dfdf');

    inc(epinfo.x);
  end;
  EpInfo.x:=i;

 result:=str;
 *)
 for i:=0 to high(Eparr) do str:=str+Eparr[i];{ a revoir}
end;

{Fonction qui permet d'évaluer des expressions}
function EvalEp(Epstr:string;rinfo:Prinfo;ForUser:boolean):integer;
begin
  result:=EvalEpEx(Epstr,'',0,rinfo,foruser,nil);
end;
{Fonction qui permet d'évaluer des expressions}
function EvalEpEx(Epstr:string;lrootStr:string;Keyvalue:integer;rinfo:prinfo;forUser:boolean;scrInfo:PscrInfo):integer;
var
  gar:strarr;
  EpInfo:PepInfo;
  str:string;
begin
  New(EpInfo);
  fillEpInfo(EpInfo);
  gar:=getdecompose(Epstr,opstr,true);
  EpInfo.ForUser:=ForUser;
  strcopy(EpInfo.ListRootStr,pchar(lrootstr));
  EpInfo.ErrId:=E_none;
  Epinfo.x:=-1;
  Epinfo.y:=-1;
  Epinfo.PID:=ROOT_PID;
  str:=precompile(EpInfo,gar);
  gar:=EpDecompose(str,false);
  OperateInt(EpInfo,gar,rinfo);
  freeEpInfo(EpInfo);
end;
{Fonction qui permet de verifier les types Epeval compatibles}
function CheckCompatible(rinfo1,rinfo2:prinfo;rtype:integer):boolean;
begin

   case rtype of
   vt_numeric:
          begin
          result:=(rinfo1.rtype=vt_integer) or (rinfo1.rtype=vt_float);
          if result then
          result:=(rinfo2.rtype=vt_integer) or (rinfo2.rtype=vt_float);
          end;
   vt_char:
           begin
           result:=(rinfo1.rtype=vt_char) and (rinfo2.rtype=vt_char);
           if not result then
           result:= (rinfo1.rtype=vt_none) or (rinfo2.rtype=vt_none); {08.07.2011}
           end;
   vt_bool:
           begin
           result:=(rinfo1.rtype=vt_bool) and (rinfo2.rtype=vt_bool);
           end;
   vt_integer:
           begin
           result:=((rinfo2.rtype=vt_integer) or (rinfo2.rtype=vt_float))
                   and ((rinfo1.rtype=vt_integer) or (rinfo1.rtype=vt_float));
           end;
   vt_float:
           begin
           result:=((rinfo2.rtype=vt_integer) or (rinfo2.rtype=vt_float))
                   and ((rinfo1.rtype=vt_integer) or (rinfo1.rtype=vt_float));
           end;
   vt_none: {Permet de supporter les procédure 25.08.2008}
           begin
           result:=rinfo2.rtype=vt_none;   {A REVOIR}
           end;
   end;
   {revision permet de supporter les function qui n'ont pas de valeur de retour 25.08.2008
   if rinfo1.rtype=vt_none then
   begin
   Strcopy(rinfo1.CharValue,'');
   rinfo1.IntValue:=0;
   rinfo1.floatvalue:=0;
   rinfo1.BoolValue:=false;
   result:=true
   end;
   if rinfo2.rtype=vt_none then
   begin
   Strcopy(rinfo2.CharValue,'');
   rinfo2.IntValue:=0;
   rinfo2.floatvalue:=0;
   rinfo2.BoolValue:=false;
   result:=true
   end;           }


end;

{Fonction d'initialisation des elements de Epeval}
function initEval:boolean;
var
  DefaultProcInfo:PevalProcessInfo;
begin
  Reg_Operators;
  Reg_Functions;
  Reg_Const;
  if typelist=nil  then typelist:=Tlist.create;
  {$IFDEF SCRIPTENABLE} reg_scr_op;{$ENDIF}
  lastNameSpaceID:=0;
  tmpNumSerial:=-1;
  {indique le process par default}
  new(DefaultProcInfo);
  defaultProcInfo.pId:=ROOT_PID;
  defaultProcinfo.AppHandle:=0;
  defaultProcinfo.Locked:=false;
  if evalProcessList=nil then evalProcessList:=Tlist.Create;
  evalprocesslist.Add(DefaultProcInfo);

    //regsellistfunc;
end;
{Fonction initialisatrice de rinfo}
function Fillrinfo(rinfo:prinfo):integer;
begin
  rinfo.CharValue:=stralloc(256);
  rinfo.CharBuffSize:=strBufSize(rinfo.CharValue);
  strcopy(rinfo.CharValue,'');
  rinfo.IntValue:=0;
  rinfo.floatvalue:=0;
  rinfo.BoolValue:=false;
  rinfo.PID:=ROOT_PID;
  //rInfo.child:=nil;{update 20 05 2010}
  rinfo.access:=aPrivate;
  rinfo.isReference:=false;
  rinfo.rtype:=vt_null;
  rinfo.group:=nil;
  rinfo.heritedNameSpace:=nil;
  rinfo.reference:=nil;
  rinfo.DefaultValue:=nil;
  rinfo.name:='';
  rinfo.rtypestr:='';
  rinfo.key:='';
end;
{Fonction qui permet d'enregistrer une fonction}
function SetFunc(PID:integer;func:PFunc;Name,groupe:string):integer;
var
  i:integer;
  traited:boolean;

begin
  if funclist=nil then funclist:=tlist.Create;
  if (not(assigned(func.groupe)))           then  func.groupe:=E_STRING('');
  if (not(assigned(func.params)))           then  func.params:=E_STRING('');
  if (not(assigned(func.heritedNameSpace))) then  func.heritedNameSpace:=E_STRING('');

  traited:=false;
  for i:=0 to funcList.Count-1 do
  begin
     if (Pfunc(funclist[i]).name=name ) and (CanAccessProc(Pfunc(funclist[i]).PID,PID)) then
     if( groupe='') or (Pfunc(funclist[i]).groupe= groupe) then
     begin
     //func.name:=name;
     if assigned(func.groupe) then strDispose(func.groupe);
     func.groupe:=E_STRING(groupe);
     funcCopy(Pfunc(funclist[i]),func);
     //PFunc(funclist[i])^:=(func)^;
     traited:=true;
     end;
  end;
  if not traited then
  funclist.Add(func);
end;

{Fonction qui permet d'enregistrer une constante}
function SetConst(constinfo:PconstInfo;name,groupe:string):integer;
var
  i:integer;
  Traited:boolean;
begin
  traited:=false;
  if constlist=nil then constlist:=tlist.Create;
  for i:=0 to constlist.Count-1 do
  begin
    if PconstInfo(constlist[i]).name=name then
    begin
    if (groupe='') or (PconstInfo(constlist[i]).groupe=groupe) then
    begin
       constinfo.name:=Pgchar(name);
       constinfo.groupe:=Pgchar(groupe);
       PconstInfo(constlist[i])^:=constinfo^;
       traited:=true;
    end;
    end;
  end;
  if not traited then
  constList.Add(constinfo)
end;

{fonction qui permet de convertir la valeur d'un rinfo a une valeur compatible a type
donne. Les types supporte sont vt_char,vt_numeric and vt_date}
function ConvertRinfoValueType(rinfo:Prinfo;rtype:integer;replacetype:boolean):boolean;
var
  str:string;
  prtype:integer;
  v:double;
begin
  result:=true;
  prtype:=rinfo.rtype;
  if (rtype=vt_integer) and (prtype=vt_char) and (trystrtofloat(rinfo.charvalue,v)) then
    begin
      rinfo.floatvalue:=v;
      rinfo.intvalue:=round(v);
   end
   else
   if (rtype=vt_char) and ((prtype=vt_integer) or (prtype=vt_float) or (prtype=vt_numeric)) then
   begin
      v:=rinfo.floatvalue;
      str:=floattostr(v);
      RINFO_COPYTEXT(rinfo,Pchar(str),length(str)+1);
    end
    else
    if (rtype=vt_char) and ( prtype=vt_date) then
    begin
      str:=datetostr(rinfo.floatvalue);
      RINFO_COPYTEXT(rinfo,Pchar(str),length(str)+1);
    end
    else
    begin
      result:=false;
    end;
    if (result) and (replacetype) then  rinfo.rtype:=rtype;
end;

{fonction qui permet de verifier si les paramètres de la fonction trouvé avec GetFuncEx correspond
aux caractéristiques des paramètre de la fonction lors de sa déclaration}
function CheckFuncParam(func:Pfunc;SearchInfo:PFuncSearchInfo):integer;
var
  i:integer;
  str:string;
  rtype,prtype:integer;
  v:double;
begin
  result:=0;
  if searchInfo.ParamList.Count>searchInfo.DeclarationArgList.Count then
  begin
    result:=-2; {trop de paramètres}
    //showmessage('trop de paramètres');
    exit;
  end;
  for i:=0 to searchInfo.ParamList.Count-1 do
  begin
    rtype:=PParamInfo(searchInfo.DeclarationArgList[i] ).rtype;
    prtype:=PParamInfo(searchInfo.ParamList[i] ).rtype;
    if not CheckCompatible(PParamInfo(searchInfo.DeclarationArgList[i] ),PParamInfo(searchInfo.ParamList[i]),rtype) then
    if  (PParamInfo(searchInfo.DeclarationArgList[i] ).rtype<>vt_none) then
    {$IFDEF VTYPE_COMPATIBLE_CONVERT}
    if not ConvertRinfoValueType(PParamInfo(searchInfo.paramlist[i] ),PParamInfo(searchInfo.DeclarationArgList[i] ).rtype,false) then
    {$ENDIF}
    begin
        {$IFDEF DEBUG_MODE}
        showmessage(inttostr(PParamInfo(searchInfo.DeclarationArgList[i] ).rtype)+'  '+inttostr(PParamInfo(searchInfo.ParamList[i]).rtype ));
        {$ENDIF}
        result:=-3;  {paramètre non compatible}

        //showmessage('paramètres incompatible');
         break;
     end;
  end;
  for i:=(searchInfo.ParamList.Count) to (searchInfo.DeclarationArgList.Count-1) do
  begin
    //showmessage(inttostr(searchInfo.ParamList.Count)+'   '+ inttostr(searchInfo.DeclarationArgList.Count));
    if PParamInfo(SearchInfo.DeclarationArgList[i]).DefaultValue='' then
    begin
       result:=-4;    {paramètre non valides}

       //showmessage('paramètre non valide');
        break;
    end;

  end;
  // showmessage(inttostr(result));
end;
{fonction qui permet d'avoir la liste des fonctions d'un namespace donné}
function GetFuncs(PID:integer;group:string;lister:pointer):boolean;
var
  i:integer;
  func:pfunc;
begin
  if funclist=nil then funclist:=Tlist.Create;
  i:=0;
  while not(i=funclist.count) do
  begin
    if (CanAccessProc(pfunc(funclist[i]).PID,PID)) and (gstrcomp(pfunc(funclist[i]).groupe,Pgstring(group))=0) then
    begin
      new(func);
      fillfunc(func);
      //func^:=pfunc(funclist[i])^;
      funcCopy(func,pfunc(funclist[i]));
      result:=FuncLister(lister)(func);
      if result=false then  break;
    end;
    inc(i);
  end;
  //result:=true;

end;

{Fonction qui permet d'avoir des informations sur une function
revision 16. 08.2010}
function GetFunc(PID:integer;name,groupe:string;rfunc:Pfunc):integer;
begin
  result:=  GetFuncEx(PID,name,groupe,rfunc,nil);
  //showmessage(groupe);
end;
{fonction qui permet de rechercher une fonction avec paramètre avancé:
searchInfo:Permet de spécifier les paramètre entrée pour rechercher avec précision
la fonction correspondante (utile pour le surcharge des fonctions)
02.09.2010}

function GetFuncEx(PID:integer;name,groupe:string;rfunc:Pfunc;SearchInfo:PFuncSearchInfo):integer;

type
  dfoundlocation=(fnone,froot,fdependcy,fchild,fgroup,finstance,frunning_methode);
var
  i,a,ifound:integer;
  Found:dfoundlocation;
  ns:integer;
begin
  result:=-1;
  Found:=fnone;
  ifound:=-1;
  for i:=0 to funclist.Count-1 do
  begin
   if (string(pfunc(funclist[i]).name)=string(name))  then
   begin
        //showmessage(Pfunc(funclist[i]).name+'___'+Pfunc(funclist[i]).groupe+'___#__'+name+'___'+groupe);
        //showmessage(groupe);
       if (getScrInfotype(PID,groupe)=scr_class_instance) or(getScrInfotype(PID,groupe)=scr_running_methode) then
        begin
          ns:=IndexFromNamespace(groupe,PID);
          if (getScrInfotype(PID,groupe)=scr_running_methode) then ns:=IndexFromNamespace(Instance_ExtractName(PID,groupe),PID);
          if ns<>-1 then
          if IsClassMethode(PID,pfunc(funclist[i]),PscrInfo(namespacelist[ns]).heritedNameSpace) then
          begin
            found:=fInstance;
            if getScrInfotype(PID,groupe)=scr_running_methode then
            found:=frunning_methode;
          end; 
        end;
        if (string(Pfunc(funclist[i]).groupe)=string(groupe)) {and (found<>fchild)} then
        Found:=fgroup
        else
        //if  (string(groupe='')) and (found=fnone) then Found:=froot
        if  (string(Pfunc(funclist[i]).groupe)='') and (found=fnone) then
        begin
           Found:=froot;
             // showmessage('found:'+ Pfunc(funclist[i]).name);
        end
        else
        if isChildNamespace(PID,groupe,Pfunc(funcList[i]).groupe)  then
        begin
        Found:=fchild;
        //showmessage('chilfuncfound');
        end
        else
        if (isNameSpaceDependency(PID,Pfunc(funclist[i]).groupe,groupe)) then
        found:=fdependcy;
        if (found<>fnone) and ((ifound=-1)or(searchInfo<>nil)) then ifound:=i;
        {verification avancée}
        if (SearchInfo<>nil)and (found<>fnone) then
        begin
          for a:=searchInfo.DeclarationArgList.Count-1 downto 0 do
          begin
            dispose(searchInfo.DeclarationArgList[a]);
            searchInfo.DeclarationArgList.Delete(a);
          end;
          getArgInfo(PID,pfunc(funclist[i]),searchInfo.DeclarationArgList);
          result:=CheckFuncParam(pfunc(funclist[i]),searchInfo);
          //showmessage('into result'+inttostr(result));
        end;

    end;
        if result=0 then break;
        {if ((found=fchild) or (found=fgroup)) and (result=0) and (searchInfo<>nil) then corrected 03.04.2012
        begin
          //        showmsg(pfunc(funclist[i]).params);
          //sleep(1);
          break;
        end; }
  end;

  if (found<>fnone) and (searchInfo<>nil) and (result<>0) then   found:=fnone;

  //if found<>fnone then   showmessage('fonction trouvée');
  if (found<>fnone)   then
  begin
        //showmessage('ifound');
        //if (pfunc(funclist[i]).access=aPrivate) and (ischildNameSpace(groupe,Pfunc(funclist[i]).groupe)) then
     if (pfunc(funclist[ifound]).access=aPrivate) and (not((found=fchild) or (found=fgroup)or (found=frunning_methode))) then
     begin
     Found:=fnone;
       result:=-5; {see evalfunction for correspondance}
     end;
     if Found<>fnone then
     begin
     //rfunc^:=Pfunc(funclist[ifound])^;
     funcCopy(rfunc,Pfunc(funclist[ifound]));
     //break;
     result:=0;
     end;
  end;

end;

{Fonction qui permet d'avoir des informations sur une constante}
function GetConst(name,groupe:string;rconst:Pconstinfo):integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to constlist.Count -1 do
  begin
    if string(PconstInfo(constlist[i]).name)=string(name) then
    if (string(PconstInfo(constList[i]).groupe)=string(groupe)) or (string(groupe)='') then
    begin
    rconst^:=PconstInfo(constlist[i])^;
    result:=0;
    end;
  end;
end;
{fonction qui permet d'avoir la liste des variables}
function Getvars(PID:integer;group:string;lister:pointer):boolean;
var
  i:integer;
  varinfo:Pvarinfo;
begin
  if varlist=nil then varlist:=Tlist.Create;
  i:=0;
  while not (i=varlist.count)  do
  begin
     if CanAccessProc(pvarinfo(varlist[i]).PID,PID) and (gstrcomp(pvarinfo(varlist[i]).group,Pgstring(group))=0) then
     begin
        new(varinfo);
        fillrinfo(varinfo);
        rInfoCopy(varinfo,pvarinfo(varlist[i]));
        if varLister(lister)(varinfo)=false then break;
     end;
     inc(i);
  end;

  result:=true;
end;
{Fonction qui permet d'avoir des informations sur une variable}
function Getvar(PID:integer;name,groupe:string;rvar:PvarInfo):integer;
var
  varinfo:pvarinfo;
begin
  result:=-1;
  varinfo:=getvarAdress(PID,name,groupe);
  if varinfo<>nil then
  if (varinfo.access=aPrivate)  and not(ischildnamespace(PID,groupe,varinfo.group) )then
  begin
        //Found:=fnone;
        result:=-5;
        //showmessage('private');
  end
  else
  begin
    //rvar^:=varinfo^;
    rInfoCopy(rvar,varinfo);
    result:=0;
  end;
end;

{fonction qui permet de rechercher l'adresse d'une variable}
function GetvarAdress(PID:integer;name,groupe:string):Pvarinfo;
type
  dfoundlocation=(fnone,froot,fdependcy,fchild,fgroup);
var
  i,ifound:integer;
  Found:dfoundlocation;
begin
  result:=nil;
  Found:=fnone;
  ifound:=-1;
  if   varlist=nil then varlist:=Tlist.create;
  for i:=0 to varlist.Count -1 do
  begin      //showmessage(name);
    if (string(PvarInfo(varlist[i]).name)=string(name)) and (CanAccessProc(PvarInfo(varlist[i]).PID,PID)) then
    begin

       //showmessage(PvarInfo(varlist[i]).name+'___'+PvarInfo(varlist[i]).group+'_____'+groupe);
       if (string(groupe)=string(PvarInfo(varList[i]).group))  then
       begin
       found:=fgroup;  //showmessage('kjk:'+PvarInfo(varList[i]).group);
       end
       else
       if  (string(PvarInfo(varList[i]).group)='') and (found=fnone) then Found:=froot
       else
       if isChildNamespace(PID,groupe,PvarInfo(varList[i]).group) then
       begin
       Found:=fchild ;
         //showmessage(PvarInfo(varlist[i]).name+'___'+PvarInfo(varlist[i]).group+'_____'+groupe);

       end
       else
       if (isNameSpaceDependency(PID,PvarInfo(varlist[i]).group,groupe)) then
       found:=fdependcy;
       if (found<>fnone) and (ifound=-1) then ifound:=i;
    end;
        
        if (found=fchild) or (found=fgroup) then begin    break;end;

    end;
    { if (found<>fnone) then
    if (pvarinfo(varlist[ifound]).access=aPrivate) and (not((found=fchild) or (found=fgroup))) then
    begin
        Found:=fnone;
        showmessage('private');
    end; }
     if Found<>fnone then
     begin
        result:=PvarInfo(varlist[ifound]);
        //rvar.name:=PvarInfo(varlist[ifound]).name;

      //showmessage(rvar.name);
      
       //break;
       //result:=0;
     end;
     //if (trim(rvar.name)='') and (result=0) then showmessage('vide varname');
     //if result=0 then     showmessage(name+'____getvar____'+PvarInfo(varlist[ifound]).name);
    //if (PvarInfo(varList[i]).access=aPrivate) and ischildNameSpace(groupe,Pvarinfo(varlist[i]).group) then
    //Traited:=true;
      //if (PvarInfo(varList[i]).group=groupe) or (groupe='') or (ischildNameSpace(Pvarinfo(varlist[i]).group,groupe)) then

    //if (ischildNameSpace(Pvarinfo(varlist[i]).group,groupe)) then
   { if traited then
    begin
    rvar^:=PvarInfo(varlist[i])^;

    result:=0;
    break;
    end;
    end;}

end;
{Fonction qui permet de supprimer une variable}
function UnsetVar(PID:integer;varStr:string;group:string):integer;
var
  varinfo:Pvarinfo;
  i:integer;
begin
  varinfo:=GetVarAdress(PID,varStr,group);
  result:=-1;
  for i:=0 to varlist.Count-1 do
  if varlist[i]=(pointer(varinfo)) then
  begin
      //StrDispose(Prinfo(varlist[i]).CharValue);
      freerInfo(varlist[i]);
      varlist.Delete(i);
      //showmessage(' delete var'+varstr);
    result:=0;
    exit;
  end;

end;

{Fonction qui permet d'avoir des informations sur un operateur}
function GetOperator(name:string;rop:POperator):integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to operatorlist.Count-1 do
  begin
     if (string(poperator(operatorlist[i]).name)=string(name)) then
     begin
     rop^:=Poperator(operatorlist[i])^;
     //showmessage(rop.name+'____');
     result:=0;
     end;
  end;

end;

{fonction qui permet d'ajouter une variable}
function Setvar(PID:integer;rvar:PvarInfo;const EraseExisting:boolean=false):integer;
var
  i:integer;
begin
  result:=-1;
  rvar.PID:=PID;
  //showmessage(rvar.name+'  pid:'+inttostr(PID)+' group:'+rvar.group);
  if   varlist=nil then varlist:=Tlist.create;
  if (not(assigned(rvar.group)))               then  rvar.group:=E_STRING('');
  if (not(assigned(rvar.reference)))           then  rvar.reference:=E_STRING('');
  if (not(assigned(rvar.heritedNameSpace)))    then  rvar.heritedNameSpace:=E_STRING('');
  if (not(assigned(rvar.DefaultValue)))        then  rvar.DefaultValue:=E_STRING('');


  for i:=0 to varlist.Count -1 do
  begin     //  showmessage(name);
    if (string(PvarInfo(varlist[i]).name)=string(rvar.name))  and (CanAccessProc(PvarInfo(varlist[i]).PID,PID))then
    if (string(PvarInfo(varList[i]).group)=string(rvar.group)) or (string(rvar.group)='') then
    begin
    if not EraseExisting then showmessage('similar varinfo'+rvar.name+'__' +rvar.group);
    rinfoCopy(PvarInfo(varlist[i]),rvar);
    freerinfo(rvar);
    //PvarInfo(varlist[i])^:=rvar^;

    result:=0;
    exit;
    end;
  end;
  varlist.Add(rvar);
  
  result:=0;
end;

//EVALEP pour l'évaluateur de script
function scr_EvalEp(Epstr:string;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;scr:PscrInfo):integer;
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
  if scr<>nil then
  begin
  //EpInfo.scr_scr:=scr.instructions;
  //EpInfo.scr_index:=scr.index;
  //EpInfo.scr_cmd:=scr.cmd;
  //EpInfo.scr_cmdArg:=scr.cmdArg;
  EPInfo.scr:=scr;
  EpInfo.IncorporetedScript:=Scr.IncorporetedScript;
  EPinfo.PID:=scr.PID;
  end;
  epInfo.errId:=E_none;


 //gar:=EPprecompile(EpInfo,gar);
 //showmessage('EPSTR____'+Epstr+'___'+inttostr(length(gar)));
 // showmessage(str);
 // for i:=0 to high(gar) do showmessage(gar[i]);
 // gar:=EpDecompose(str,false);
  OperateInt(EpInfo,gar,rinfo);
  epInfo.ErrStrPos:=0;
  EpInfo.ErrRigthLnCount:=0;
  str:='';
  (*
  if (EpInfo.ErrId<>E_None) and (not(EpInfo.ErrDeclationMode=errAlternative)) then
  begin
     gar2:=EpParse(Epstr,false);
     for i:=(EpInfo.ErrPos+1) to high(gar2)  do str:=str+gar2[i] ;

     EpInfo.ErrRigthLnCount:= xcount_delimiter(#10#13,str); {car par defaut xcount_delimiter donne 0  sil ne trouve de correcpondance}
      //showmessage(str+'___'+inttostr(Epinfo.ErrRigthLnCount));
     str:='';
     //showmessage(inttostr(epinfo.errpos));
     if EpInfo.ErrDeclationMode<>errNamespace then
     begin
        for i:=0 to (EpInfo.ErrPos)  do str:=str+gar2[i] ; EpInfo.ErrStrPos:=length(str);
     end;

  end;
  *)
  if (EpInfo.ErrId<>E_None) and (EpInfo.ErrDeclationMode=errNormal) then
  begin
     gar2:=EpParse(Epstr,false);
     for i:=(EpInfo.ErrPos+1) to high(gar2)  do str:=str+gar2[i] ;

     EpInfo.ErrRigthLnCount:= xcount_delimiter(#10#13,str); {car par defaut xcount_delimiter donne 0  sil ne trouve de correcpondance}
      //showmessage(str+'___'+inttostr(Epinfo.ErrRigthLnCount));
     str:='';
     //showmessage(inttostr(epinfo.errpos));
     for i:=0 to (EpInfo.ErrPos)  do  if (i<=high(gar2)) then str:=str+gar2[i] ;
     EpInfo.ErrStrPos:=length(str); {équivalent à GetEpStrErrPos(Epstr:string);}
     setLength(gar2,0);
  end;

  if scr<>nil then
  begin
    scr.cmd:=EpInfo.scr.cmd;
    scr.cmdArg:=EpInfo.scr.cmdArg;
  end;
  result:=EpInfo.ErrId;
  SetLength(gar,0);
end;



{Fonction qui permet de précompiler une expression( remplace les
champs virtuelles par leurs expressions CORRECTION Precompile}
function EpPrecompile(EpInfo:pepinfo;Eparr:strarr):strarr;
var
  str,mo:string;
 // field:pvfield;
  i:integer;
begin
(*  i:=EpInfo.x;
  Epinfo.x:=0;
 {for i:=0 to High(eparr) do
   begin
     mo:=eparr[i];     showmsg(pchar('part:'+mo+'dfd'));
   end; }
  while not (epinfo.x>high(eparr)) do
  begin

    new(field);
    if findvfield(eparr[epinfo.x],field)then
    begin
    //showmessage('Virtual Field: '+eparr[epinfo.x]);
    {Verifie si il ya un point derriere expemple:[char:inscript.nationalite]'}
    if (EpInfo.x-1)<0 then
    Eparr[EpInfo.x]:=GetvFieldEp(field,Epinfo,Eparr)
    else
    if (Eparr[EpInfo.x-1]<>'.')  then
    Eparr[EpInfo.x]:=GetvFieldEp(field,Epinfo,Eparr);

  
    end;
     
     If Eparr[epinfo.x]='"' then
     EpInfo.x:=EpInfo.x+1;
     inc(epinfo.x);
  end;
  EpInfo.x:=i;

 result:=Eparr; *)
 result:=Eparr;{ a revoir}
end;

// function qui permet de conter les nombres d'apparition d'un mot dans un string
{a revoir}
function xcount_delimiter(delimiter,str:string):integer;
var
  text:string;
  i:integer;
begin
  i:=0 ;{ pour la dernière ligne}
  text:=str;
  while (pos(delimiter,text)>0) do
  begin
    inc(i);
    text:=copy(text,pos(delimiter,text)+length(delimiter),length(text)- pos(delimiter,text));
  end;
  //showmessage(str);
  result:=i;
end;

{fonction qui permet d'avoir des infos sur un EvalProcess}
function GetEvalProcessInfo(PID:integer;rEvPInfo:PevalProcessInfo):integer;
var
  i:integer;
begin
   result:=-1;
   for i:=0 to EvalProcessList.Count-1 do
   if PevalProcessInfo(EvalProcessList[i]).PID=PId then
   begin
     rEvPInfo^:=PevalProcessInfo(EvalProcessList[i])^;
     result:=0;
     break;
   end;

end;
{fonction qui permet si un pid peut avoir acces aux données d'un autre pid}
function CanAccessProc(PID,UserPID:integer):boolean;
var
  EvalProcess:PEvalProcessInfo;
begin
  new(EvalProcess);
  if Pid=-1 then
    result:=true
  else
  if pid=UserPid then
    result:=true
  else
    if GetEvalProcessInfo(Pid,EvalProcess)=0 then
    if (pid<>UserPid) then
    begin
        result:= EvalProcess.locked=false;
    end;
  dispose(EvalProcess);
  //if pid<>UserPid then showmessage(inttostr(PID)+'  '+inttostr(UserPid));
end;
{fonction qui permet d'avoir le type d'un PscrInfo}
function GetScrInfoType(PID:integer;namespace:string):PscrType;
var
  ns:integer;
begin
  ns:=IndexFromNameSpace(namespace,PID);
  //if ns=-1 then showmessage(namespace);
  result:=PscrInfo(namespacelist[ns])._type;

end;
{fonction qui permet d'avoir l'acces par défaut des membres d'un PscrInfo}
function GetScrMembersDefAccess(PID:integer;namespace:string):TevalAccess;
var
  ns:integer;
begin
  ns:=IndexFromNameSpace(namespace,PID);
  //if ns=-1 then showmessage(namespace);
  if ns<>-1 then
  result:=PscrInfo(namespacelist[ns]).defaultMemberAccess
  else
  result:=aPublic;
end;
{function qui ajoute un namespace dans la liste des namespace}
function AddNamespace(PID:integer;scr:PscrInfo;name:string;AutoCreateParent:boolean):integer;
var
   child:PNameSpacedepends;
   i:integer;
   gar:strarr;
   str:string;
   newScr:PscrInfo;

begin
  result:=-1;
  if namespaceList=nil then namespaceList:=Tlist.Create;
  scr.PID:=PID;
  for i:=0 to namespacelist.Count-1 do
  if (CanAccessProc(PscrInfo(namespacelist[i]).PID,PID)) and
  (gstrcomp(PscrInfo(namespacelist[i]).Name,pgstring(name))=0) then  exit;


  scr.Name:=Pgstring(name);
  {cherche le namespace parent}
  for i:=length(str) downto 1 do
  if str[i]='.' then
  begin
     scr.parent:=Pgstring(copy(str,1,i));
  end;
  {ajout du namespace}
  namespaceList.Add(scr);
  result:=namespaceList.Count-1;
  {auto ajout des namespace parent }
  if AutoCreateParent    then
  begin
    str:='';
    gar:=getDecompose(scr.Name,'.',true);
    for i:=0 to high(gar) do
    begin
     if (gar[i]='.') and (indexFromnamespace(str,PID)=-1) then
     begin
       new(newScr);
       fill_scr(newScr);
       newScr.Name:=Pgstring(str);
       addNamespace(scr.PID,newScr,str,AutoCreateParent)
     end;
     str:=str+ gar[i];
    end;
  end;


end;
{fonction qui permet d'avoir la liste des namespaces ayant pour parent une namespace donnée}
function GetNamespaces(PID:integer;Parent:string;lister:pointer):boolean;
var
  //child:PNameSpacedepends;
  ns:pchar;
  i:integer;
begin
  //new(child);
  //showmessage('ns:'+namespace);
  for i:=0 to namespaceList.Count-1 do
  if (gstrcomp(PScrInfo(namespaceList[i]).parent,Pgstring(parent))=0) and (CanAccessProc(PscrInfo(namespaceList[i]).PID,PID)) then
  if (gstrcomp(PScrInfo(namespaceList[i]).Name,Pgstring(parent))<>0) then
  begin
    ns:=stralloc(256);
    strcopy(ns,pchar(PScrInfo(namespaceList[i]).name));
    result:=namespacelister(lister)(ns,sizeof(ns));

  end;
  i:=0;
end;


{fonction qui permet d'obtenir l'index d'un namespace dans la liste }
function IndexfromNamespace(namespace:string;PID:integer):integer;
var
  i:integer;
begin
  result:=-1;
  for i:= 0 to namespacelist.count-1 do
  if (CanAccessProc(PscrInfo(namespacelist[i]).PID,PID)) then
  if gstrcomp(PscrInfo(namespacelist[i]).Name,Pgstring(namespace))=0 then
  begin
    result:=i;
    break;
  end;
  //showmessage(inttostr(result)+' index of namespace');

end;
function IndexOfNameSpace(namespace:string;PID:integer):integer;
begin
   result:=IndexFromNameSpace(namespace,PID);
end;

{recherche un namespace a partir du nom privé  du nom de ses parent
namspaceStr:nom privé  du nom de ses parent
parent:nom complet du namespace
principe:s'il n'arive pas a trouver le namespace continue automatiquement la
recherche dans les namspaces parents:}
function  Find_hNamespace(PID:integer;namespaceStr,parent:string):integer;
var
  i,a:integer;
  gar:strarr;
begin
    i:=indexFromNameSpace(parent+'.'+namespaceStr,PID);
    if i=-1 then
    begin
      gar:=getScrDependency(PID,parent,true);
      for a:=0 to high(gar) do
      begin
        i:=indexFromNameSpace(gar[a]+'.'+namespaceStr,PID);
        if i<>-1 then break;
      end;
    end;
    result:=i;
 end;

 {fonction qui permet de cloner les variables d'un namespace dans un autre namespace}
function ns_varClone(PID:integer;namespace,destNamespace:string;includeHeritage:boolean;Mode:TEvalCloneMode):integer;
var
  i,nsid:integer;
  varinfo:Pvarinfo;
begin
  varinfo:=nil;
  nsid:=indexFromNameSpace(namespace,PID);
  if  (Mode=clmClass) and (pscrInfo(namespacelist[nsid])._type<>scr_class) then exit; {evite de copier les variables du namespace conteneur si class}
  for i:=0 to varlist.count-1 do
  if (Pvarinfo(varlist[i]).group=namespace) and (CanAccessProc(Pvarinfo(varlist[i]).PID,PID)) then
  begin
     if mode=clmClassInstance then
     begin
       varinfo:=GetVarAdress(PID,PvarInfo(varlist[i]).name,destNamespace);
       if varinfo<>nil then rInfoCopy(varinfo,PvarInfo(varlist[i]))//varinfo^:=PvarInfo(varlist[i])^;
     end
     else
     begin
       new(varinfo);
       fillrinfo(varinfo);
       rInfoCopy(varinfo,PvarInfo(varlist[i]));
       //varinfo.CharValue:='hjhj';
       //showmessage(varinfo.group+':'+varinfo.name+'___'+destnamespace);
       if assigned(varInfo.group) then strDispose(varinfo.group);
       varinfo.group:=E_STRING(destNamespace);
       Setvar(PID,varinfo);
     end;
  end;
 { if (includeHeritage) and (pscrInfo(namespacelist[nsid]).parent<>'') then
  ns_varClone(PID,pscrInfo(namespacelist[nsid]).parent,destNamespace,IncludeHeritage,mode);
 }
  if (includeHeritage) and (pscrInfo(namespacelist[nsid]).heritedNameSpace<>'') then
  ns_varClone(PID,pscrInfo(namespacelist[nsid]).heritedNameSpace,destNamespace,IncludeHeritage,mode);
end;
{fonction qui permet de cloner toutes les fonctions d'un namespace dans un autre namespace}
function ns_functionClone(PID:integer;namespace,destNamespace:string;includeHeritage:boolean;Mode:TevalCloneMode):integer;
var
  i,nsid:integer;
  func:Pfunc;
begin
  nsid:=indexFromNameSpace(namespace,PID);
  if  (mode=clmClass) and (pscrInfo(namespacelist[nsid])._type<>scr_class) then exit; {evite de copier les variables du namespace conteneur si class}

  for i:=0 to funclist.count-1 do
  if (Pfunc(funclist[i]).groupe=namespace) and (CanAccessProc(Pfunc(funclist[i]).PID,PID)) then
  begin
   new(func);
   fillfunc(func);
   funcCopy(func,Pfunc(funclist[i]));
   //func^:=Pfunc(funclist[i])^;
   if assigned(func.groupe) then strDispose(func.groupe);
   func.groupe:=E_STRING(destNamespace);
   Setfunc(PID,func,func.name,func.groupe);
  end;
  if (includeHeritage) and (pscrInfo(namespacelist[nsid]).heritedNameSpace<>'') then
  ns_functionClone(PID,pscrInfo(namespacelist[nsid]).heritedNameSpace,destNamespace,IncludeHeritage,Mode);


end;


{libère les données contenu dans un Pscrinfo}
function DestroyScrContent(scr:pscrinfo):integer;
var
  i:integer;
  child,child2:PNameSpaceDepends;

begin
  for i:=high(scr.instructions) downto 0   do
  begin
    strDispose(scr.instructions[i].text);
    dispose(scr.instructions[i]);
  end;
  SetLength(scr.dependency,0);
  SetLength(scr.instructions,0);
  {while not (child=nil) do
  begin
    child:=scr.childNameSpaces;
    child2:=child.nextchild;
    dispose(child);
    child:=child2;
  end;
  }
 // Setlength(scr.scrChildsId,0);
end;
{supprimer toutes les fonctions appartenant à un groupe de variable donnné}
function deletefuncs(PID:integer;group:string):integer;
var
  i:integer;
begin
  if funclist=nil then funclist:=Tlist.Create;
  i:=0;
  while not(i=funclist.count) do
  if (CanAccessProc(pfunc(funclist[i]).PID,PID)) and (gstrcomp(pfunc(funclist[i]).groupe,Pgstring(group))=0) then
  begin
     freeFunc(pfunc(funclist[i]));
     funclist.Delete(i);
  end
  else
     inc(i);
  result:=0;
end;
{supprimer une fonctions appartenant à un groupe de variable donnné}
function UnsetFunc(PID:integer;name,group:string):integer;
var
  i:integer;
begin
  if funclist=nil then funclist:=Tlist.Create;
  i:=0;
  while not(i=funclist.count) do
  if (gstrcomp(pfunc(funclist[i]).groupe,Pgstring(group))=0) and (name=pfunc(funclist[i]).name) and (CanAccessProc(pfunc(funclist[i]).PID,PID)) then
  begin
     freeFunc(pfunc(funclist[i]));
     funclist.Delete(i);
  end
  else
     inc(i);
  result:=0;
end;
{supprimer tous les variable appartenant à un groupe de variable donnné}
function deleteVars(PID:integer;group:string):integer;
var
  i:integer;
begin
  if varlist=nil then varlist:=Tlist.Create;
  i:=0;
  while not (i= varlist.count)  do
  if CanAccessProc(pvarinfo(varlist[i]).PID,PID) and (gstrcomp(pvarinfo(varlist[i]).group,Pgstring(group))=0) then
  begin
     //Strdispose(pvarinfo(varlist[i]).CharValue);
     freerInfo(pvarinfo(varlist[i]));
     varlist.Delete(i);
  end
  else
     inc(i);

  result:=0;
end;

function deleteNamespace(PID:integer;namespace:string;deleteChild:boolean):integer;
var
  //child:PNameSpacedepends;
  i:integer;
begin
//  new(child);
  //showmessage('ns:'+namespace);
  for i:=0 to namespaceList.Count-1 do
  if (gstrcomp(PScrInfo(namespaceList[i]).Name,Pgstring(namespace))=0) and (CanAccessProc(PscrInfo(namespaceList[i]).PID,PID)) then
  begin
    deletefuncs(PID,namespace);
    deletevars(PID,namespace);
    DestroyScrContent(pscrinfo(namespacelist[i]));
    dispose(pscrinfo(namespacelist[i]));
    namespaceList.Delete(i);
    break;
  end;
  i:=0;
  if deletechild  then
  while not (i>namespaceList.Count-1) do
    if (gstrcomp(PScrInfo(namespaceList[i]).parent,Pgstring(namespace))=0) then
    begin
       //DestroyScrContent(pscrinfo(namespacelist[i]));
       //dispose(pscrinfo(namespacelist[i]));
       //namespaceList.Delete(i);
       deletenamespace(PScrInfo(namespaceList[i]).PID,PScrInfo(namespaceList[i]).Name,deletechild);
    end
    else
       inc(i);




end;

function scrFileFromNameSpace(PID:integer;namespace:string):string;
var
  id:integer;
begin
  id:=IndexFromNameSpace(namespace,PID);
  if id<>-1 then
  result:=pscrInfo(namespacelist[id]).scrFileName;
end;


function isChildNamespace(PID:integer;child,parent:string):boolean;
var
  parentId,id:integer;
 // child:PNameSpaceDepends;
begin
  //showmessage('jkjk');
  result:=false;
 
  result:=child=parent;
  //showmessage(copy(child,length(parent)+1,1));
  if not result then
  begin
    id:=IndexFromNamespace(child,PID);
    parentId:=IndexFromNameSpace(parent,PID);
  
     result:=(id<>-1)  and (ParentId<>-1) ;
     //  if result then showmessage('jkjk');
     // showmessage(child+'    '+parent);
     if result then
     result:=(copy(child,1,length(parent)+1)=parent+'.') ;
     //result:=(copy(child,1,length(parent))=parent) and (pos(copy(child,length(parent)+1,1),'.:')>0);
  end;
//  if result then showmessage('result is true');
//  showmessage(inttostr(length(copy(parent,1,length(child))))+'____'+inttostr(length(parent)));
end;

{fonction qui permet d'appeler une fonction de type virtuel déclaré par l'utilisateur}
function Call_vfunc(func:Pfunc;args:PFuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;
var
  //ParamList:TList;
  i,Intval:integer;
  //StrVal:Pchar;
  BoolVal:Boolean;
  floatVal:double;
  funcAdr:Pointer;
  a,nId:integer;
  scr:PscrInfo;
  retvar:Prinfo;
  tmpgroup:string;
  funcparam:Prinfo;
  SearchInfo:PFuncSearchInfo;


begin
  //showmessage('Call_vfunc');
  searchinfo:=args;


  if args=nil then
  begin
     new(SearchInfo);
     SearchInfo.DeclarationArgList:=Tlist.Create;
     SearchInfo.ParamList:=Tlist.Create;
     //ParamList:=TList.Create;

     GetArgInfo(EPInfo.PID,func,SearchInfo.DeclarationArgList);
     if EvalArgs(SearchInfo.ParamList,EpInfo,EParr)=0 then exit;

  end;
  //strval:=stralloc(255);

begin;
  {groupe definition}
  //showmessage(func.name+ epInfo.group);
  if (GetScrInfotype(epInfo.PID,epinfo.group)=scr_class_instance) or (GetScrInfotype(epInfo.PID,epinfo.group)=scr_running_methode) then
  begin

    tmpgroup:=string(epInfo.group)+'._tmp_'+inttostr(lastNameSpaceId+1);
    //showmessage(func.name);
    inc(lastNamespaceId);
  end
  else
  begin
    tmpgroup:=string(func.groupe)+'._tmp_'+inttostr(lastNameSpaceId+1);
    inc(lastNamespaceId);
  end;
  //if EpInfo.ErrId<>E_none then    showmessage('error before vfunc');

  for  i:=0 to searchInfo.declarationArglist.count-1 do {01.05.2011 evite de confondre les type surtout quand il s'agit de integer et float}
  begin
    if Prinfo(searchInfo.declarationArglist[i]).rtype<>vt_none then PParamInfo(searchInfo.paramlist[i]).rtype:= Prinfo(searchInfo.declarationArglist[i]).rtype;
  end;
  i:=SearchInfo.ParamList.Count-1;
  {transfert des paramètres de la function}
  while not i<0 do
  begin
    //showmessage('kjk');
    //showmessage('paramètr_   '+PParamInfo(searchinfo.DeclarationArgList[i]).name);
    New(funcParam);
    fillrinfo(funcParam);
    //funcParam^:=PParamInfo(SearchInfo.ParamList[i])^;
    rinfoCopy(funcParam,PParamInfo(SearchInfo.ParamList[i]));
    funcparam.name:=PParamInfo(SearchInfo.DeclarationArgList[i]).name;
    if assigned(funcparam.group) then strDispose(funcparam.group);
    funcparam.group:=E_STRING(tmpgroup);
    Setvar(EpInfo.PID,funcParam);
  dec(i);
  end;
  {execution de la fonction virtuelle}
   new(scr);
   new(retvar);
   FillRinfo(retvar);
   retvar.name:='result';
   retvar.group:=E_STRING(tmpgroup);
   retvar.rtype:=vt_none;
   Setvar(EpInfo.PID,retvar);

   //showmessage('execution:BLOC function virtuelle');
   scr.cmd:=-1;
   scr.error_id:=-1;
   //scr.ParentIndex:=EpInfo.groupIndex;

   {traitement spécial classs_instance et runningMehode}
   if (GetScrInfotype(epInfo.PID, epInfo.group)=scr_class_instance)or (GetScrInfotype(epInfo.PID,epinfo.group)=scr_running_methode)  then
   begin
     scr.parent:=epInfo.group;
     scr.scrFileName:='#classmethode#'+string(func.groupe);
   end
   else
   begin
    scr.parent:=func.groupe;
    scr.scrFileName:='#parent#';
   end;
   scr.heritedNameSpace:=func.groupe;
   scr.PID:=EpInfo.PID;
   Scr.IncorporetedScript:=EpInfo.IncorporetedScript;

   scr._type:=scr_running_methode;
   scr.silenceMode:=true;
   scr.Name:=Pgstring(tmpgroup);{equivalent à getNewNamespacestr()}
   //showmessage(func.groupe+'____'+func.name);
   
   //scr2.namespace:='#tmp#'+inttosstr(lastnamespaceId+1);
   //showmessage(scr.name);
   nId:=indexFromNamespace(func.heritedNameSpace,Epinfo.PID);
   if nId=-1 then
   begin
      signalerror(EpInfo,EpInfo.x,E_PERSONAL,'undef function');
      exit;
   end;

   // showmessage(PscrInfo(namespacelist[nId]).instructions[func.v_location].text);
    scr.scrFilePos:=PscrInfo(namespacelist[nid]).instructions[func.v_location].startpos;
    EpInfo.ErrId:=scr_evalEx(  PscrInfo(namespacelist[nId]).instructions[func.v_location].text,scr,epInfo.PID);
   {ratachement des erreurs: par la methode de déclaration alternatives de erreur dans le script}
   if (scr.error_id<>e_None) then
   begin

                     EpInfo.ErrDeclationMode:=errnamespace;
                     Epinfo.ErrNamespace:=E_STRING(scr.Name);
                     //EpInfo.ErrNamespace:=func.groupe;
                     Epinfo.ErrId:=scr.error_id;
                     //showmessage('vcallerror line:'+inttostr(scr.error_line));
                     //showmessage('errreur fonction'+ scr.error_msg+ ' '+ inttostr(EpInfo.ErrId));


   end
   else
   begin
     getvar(EPInfo.PID,'result',tmpgroup,rinfo);
     //showmessage(rinfo.charvalue);
     (*deletenamespace(scr.PID,scr.Name,true);
     {for i:=0 to paramlist.Count-1 do
     dispose(PparamInfo(paramlist[i]));  }
     SearchInfo.Paramlist.free;
     searchInfo.DeclarationArgList.Free;   *)
   end;
   {netoyage...}
   deletenamespace(scr.PID,scr.Name,true);
   for i:=0 to  searchInfo.ParamList.Count-1 do freerInfo(searchInfo.paramList[i]);
   for i:=0 to  searchInfo.DeclarationArgList.Count-1 do freerInfo(searchInfo.DeclarationArgList[i]);
   if args=nil then
   begin
      searchInfo.ParamList.Free;
      searchInfo.DeclarationArgList.Free;
   end;
  {fin netoyage}

   {transfers des resultats rétournés par la fonction dans rinfo}
   
   //rinfo.rtype:=vt_char;
   //rinfo.rtype:=func.rtype;
   if rinfo.rtype=vtchar then showmessage(' virtual func result vt_char');
   //showmessage(rInfo.CharValue);
   //if EpInfo.ErrId<>E_none then    showmessage( 'error after vfunc');
   //Inc(EpInfo.x ) ;

  {Mov i, EAX    }
  //showmessage(inttostr(i));

  //showmessage(inttostr(epinfo.x)+ '___' +inttostr(epinfo.y));
  //  showmessage(inttostr(EpInfo.ErrId));


 // {IMPORTANT tester errnamespae} if (epinfo.ErrId<>E_none) and (epInfo.ErrDeclationMode=errnamespace) then showmessage(Epinfo.ErrParams);


end;
end;
{permet d'obtenir un nouveau nom pour un nouveau namespace}
function GetNewNameSpaceStr:string;
begin
 inc(lastNameSpaceId);
 result:='_sysauto_ns_'+inttostr(lastNameSpaceId);
end;
{fonction qui permet de copier les erreurs d'un epinfo a un autre}
function copyEpError(source,dest:PepInfo):integer;
begin
    dest.ErrId:=source.ErrId;
    if assigned(source.ErrParams) then
    begin
      if assigned(dest.ErrParams) then dispose(dest.ErrParams);
      dest.ErrParams:=E_STRING(source.ErrParams);
    end;
    dest.ErrDeclationMode:=source.ErrDeclationMode;
    if assigned(source.ErrNamespace) then
    begin
      if assigned(dest.ErrParams) then dispose(dest.ErrParams);
      dest.ErrNamespace:=E_STRING(source.ErrNamespace);
    end;
    dest.ErrPos:=source.ErrPos;
    dest.ErrLn:=source.ErrLn;
    dest.ErrRigthLnCount:=source.ErrRigthLnCount;
    dest.ErrStrPos:=source.ErrStrPos;

end;



{fonction qui permet de traiter les reference au namespace: 08 08 2010}
function EvalNameSpaceRef(EpInfo:Pepinfo;Eparr:strarr;rinfo:prinfo):integer;
var
  i,a:integer;
  parentNamespace,ns:string;
  gar:strarr;

begin
  {traitement lorsque c'est dans le cadre d'une definition de classe ou namespace}
  if (EpInfo.cmd= work_NAMESPACEDEF) or (EpInfo.cmd= work_CLASSDEF)  then
  begin
    if rinfo.rtype=vt_namespaceRef then
    ns:=rinfo.reference+'.'+Eparr[EpInfo.x]
    else
    ns:=string(EpInfo.group)+'.'+Eparr[EpInfo.x];

    if (not((eparr[EpInfo.x-1]='class') or (eparr[EpInfo.x-1]='namespace') or (pos(eparr[EpInfo.x-1],'::.')>0))) then
    begin
      exit  {evite un erreur de synthax dans le def du nom de la classe}
    end;
   // showmessage(ns);
    rinfo.isReference:=true;
    rinfo.rtype:=vt_namespaceRef;
    if assigned(rinfo.reference) then strDispose(rinfo.reference);
    rinfo.reference:=E_STRING(ns);
    strcopy(rinfo.name,Pevchar(rinfo.name+Eparr[Epinfo.x]));
    EpInfo.traited:=true;
    exit;
    
  end;

  if rinfo.rtype=vt_namespaceref then
  begin
    i:=indexfromNamespace(rinfo.reference+'.'+Eparr[Epinfo.x],EpInfo.PID);
  end
  else
  begin
    //showmessage(EpInfo.group+'.'+Eparr[Epinfo.x]);
    i:=indexFromNameSpace(string(EpInfo.group)+'.'+Eparr[Epinfo.x],EpInfo.PID);
    if i=-1 then
    begin
      gar:=getScrDependency(EpInfo.PID,EpInfo.group,true);
      for a:=0 to high(gar) do
      begin
        //showmessage(gar[a]);
        i:=indexFromNameSpace(gar[a]+'.'+Eparr[Epinfo.x],EpInfo.PID);
        if i<>-1 then break;
      end;
    end;

  end;

  if i<>-1 then
  begin
    {PARTIE A REVOIR pour permettre de detecter les missing semi column}
    if (Epinfo.prev_traited<>pt_none) and (EpInfo.prev_traited=pt_const) then  { A REVOIR:verifie que la colonne précédante est un opérateur}
    begin
      SignalError(EpInfo,EpInfo.x,E_PERSONAL,pgstring('Missing semi column( ;) after "'+Eparr[Epinfo.x-1]+'"'));
      EpInfo.x:=EpInfo.x+1;
     exit;
     end;
    EpInfo.traited:=true;
    rinfo.rtype:=vt_namespaceRef;
    strcopy(rinfo.name,Pevchar(PscrInfo(namespacelist[i]).Name));
    rinfo.isReference:=true;
    if Assigned(rinfo.reference) then strdispose(rinfo.reference);
    rinfo.reference:=E_STRING(PscrInfo(namespacelist[i]).Name);
    epInfo.prev_traited:=pt_variable;{A REVOIR}

    //break;
  end;
end;
{fonction qui permet d'ajouter une dépendance a la liste des dependance d'un namespace}
function addScrDependency(PID:integer;namespace,dependency:string):integer;
var
  nsId,rlength:integer;
begin
  nsId:=IndexFromNamespace(namespace,PID);
  if nsId>-1 then
  begin

    rlength:=length(PscrInfo(namespacelist[nsId]).dependency);
    SetLength(PscrInfo(namespacelist[nsId]).dependency,rlength+1);
    PscrInfo(namespacelist[nsId]).dependency[rlength]:=dependency;
  end;
end;
{fonction qui permet de lister toutes les dependences d'un namespace donné}
function getScrDependency(PID:integer;namespace:string;includeParent:boolean):strarr;
var
  i,a,nsId:integer;
  str:string;
begin
  str:=namespace;
  
  for i:=length(str) downto 1 do
  if str[i]='.' then
  begin
    nsId:=IndexfromNamespace(str,PID);
    //showmessage('getscrdependency:'+str);
    if nsId<>-1 then
    begin

      for a:=0 to high(PscrInfo(namespacelist[nsId]).dependency) do
      begin
         SetLength(result,length(result)+1);
         result[high(result)]:=PscrInfo(namespacelist[nsId]).dependency[a];
      end;
      str:=copy(str,1,i-1);
      if includeParent then
      begin
        SetLength(result,length(result)+1);
        result[high(result)]:=str;
      end;
    end;
  end;
end;
{fonction qui permet de savoir si un  namespace est dependant d'un namespace donné}
function isNamespaceDependency(PID:integer;dependency,namespace:string):boolean;
var
  i:integer;nsId,dId:integer ;
begin
  nsId:=IndexFromNameSpace(namespace,PID);
  dId:= IndexFromNameSpace(dependency,PID);
  //showmessage(namespace);
  result:=false;

  result:=isChildNamespace(PID,namespace,dependency);
  //showmessage(namespace+'_______'+dependency);
  if not result then
  begin
    for  i:=0 to high(PScrInfo(namespacelist[nsId]).dependency)  do
     if (dependency=PScrInfo(namespacelist[nsId]).dependency[i]) then
     begin
       result:=true;break;
    end;
  end;
end;

{fonction qui permet de modifier le nom d'un namespace
attention: les fonction et variable qui refére sur l'ancien namespace
ontinueront a referencer sur l'ancien namespace.}
function SetScrNameSpace(PID:integer;namespacestr:string;newNamespaceStr:string):boolean;
var
  nsId:integer;
begin
  nsId:=IndexFromNamespace(namespacestr,PID);
  PscrInfo(namespacelist[nsId]).Name:=pgstring(newNamespaceStr);
end;

function fill_scr(scr:PscrInfo):integer; overload;
begin
   scr.cmd:=-1;
   scr.error_id:=-1;
   scr.PID:=ROOT_PID;
   scr.IncorporetedScript:=true;{par  defaut}
   scr.Name:=Pgstring(GetNewNameSpaceStr);
   scr.defaultMemberAccess:=aPublic;
   scr._type:=scr_namespace;
   //scr.childNameSpaces:=nil;
   result:=0;
end;

function fill_scr(scr:PscrInfo;parent:string;PID:integer):integer;overload;
begin
   scr.cmd:=-1;
   scr.error_id:=-1;
   scr.PID:=PID;
   scr.IncorporetedScript:=true;
   scr.Name:=Pchar(string(parent)+'.'+GetNewNameSpaceStr);
   scr.defaultMemberAccess:=aPublic;
   scr._type:=scr_namespace;
   //scr.childNameSpaces:=nil;
   result:=0;
end;

function GetNewNumericId:integer;
begin
  inc(tmpNumSerial);
  result:=tmpNumSerial
end;
{cré un nouveau processus d'évaluation}
function CreatEvalProcess(ProcessInfo:PevalProcessInfo):integer;
begin
  if evalProcessList=nil then evalProcessList:=Tlist.Create;
  if ProcessInfo<>nil then
  begin
      ProcessInfo.PID:=GetNewNumericId;
      evalProcessList.Add(ProcessInfo);
  end;
  result:=ProcessInfo.PID;
end;
{delete nouveau processus d'évaluation}
function DeleteEvalProcess(PID:integer):boolean;
var
  i:integer;
begin
  if evalProcessList=nil then evalProcessList:=Tlist.Create;
  result:=false;
  for i:=0 to evalProcessList.Count-1 do
  if PEvalProcessInfo(evalProcessList[i]).PID=PID then
  begin
      result:=true;
      dispose(evalProcessList[i]);
      evalProcessList.Delete(i);
      break;
  end;
  
end;


{Défini le handle de fenètre de sorti par defaut}
function SetEvalHook(Hook:PEvalEventHook):integer;
var
  i:integer;
begin
  {verifie si le processus n'est pas protégé pour un AppHandle différent du handle du evalprocess}
  for i:=0  to evalProcessList.Count-1 do
  if (PEvalProcessInfo(evalProcessList[i]).PID=hook.PID)  then
  if (PEvalProcessInfo(evalProcessList[i]).Locked=true)  then
  if (PEvalProcessInfo(evalProcessList[i]).AppHandle<>hook.appHandle) then
  begin
    Showmessage('process protected');
    exit;
  end;
  {ajoute le hooker}
  if evalEventsHooks=nil then evalEventsHooks:=Tlist.Create;
   hook.SwitchToSecondScreen:=false;
   evalEventsHooks.Add(hook);
end;
function UnsetEvalHook(AppHandle:integer):integer;
var
 i:integer;
begin
 if evalEventsHooks=nil then EvalEventsHooks:=Tlist.Create;
 for i:=0  to evalEventsHooks.Count-1 do
  if (PEvalEventhook(evalEventsHooks[i]).AppHandle=AppHandle)  then
  begin
    FreeMem(evalEventsHooks[i],PEvalEventhook(evalEventsHooks[i]).cbsize);{faire attention a spécifier tjr cbsize}
    evalEventsHooks.Delete(i);
    break;
  end;
end;

{appelle la fonction screenHandler pour désinner du texte sur l'écran virtuelle}
function PrintScreenText(Pid:integer;text:string):integer;
var
  i:integer;
  data:pointer;
  ScreenHandler:Pointer;
begin
  if evalEventsHooks=nil then evalEventsHooks:=Tlist.Create;
  for i:=0 to evalEventsHooks.count-1 do
  if  CanAccessProc(PEvalEventHook(evalEventsHooks[i]).PID,Pid)  then
  begin
    ScreenHandler:=PEvalEventHook(evalEventsHooks[i]).ScreenHandler;
    if (PEvalEventHook(evalEventsHooks[i]).SwitchToSecondScreen)  and
       (PEvalEventHook(evalEventsHooks[i]).SecondScrHandler<>nil) then
    begin
      ScreenHandler:=PEvalEventHook(evalEventsHooks[i]).SecondScrHandler;
    end;
    if (ScreenHandler<>nil) then
     try
       data:=PEvalEventHook(evalEventsHooks[i]).Data;
       TEvalStreamProc(ScreenHandler)(pchar(text),length(text)+1,data);
     except
        result:=-1;
     end;
  end;

end;
function PrintScreenText2(Pid:integer;text:pchar):integer;
var
  i:integer;
  str:pchar;
  ScreenHandler:Pointer;
begin
  if evalEventsHooks=nil then evalEventsHooks:=Tlist.Create;
  for i:=0 to evalEventsHooks.count-1 do
  if  CanAccessProc(PEvalEventHook(evalEventsHooks[i]).PID,Pid)  then
  begin
   ScreenHandler:=PEvalEventHook(evalEventsHooks[i]).ScreenHandler;
   if (PEvalEventHook(evalEventsHooks[i]).SwitchToSecondScreen)  and
      (PEvalEventHook(evalEventsHooks[i]).SecondScrHandler<>nil) then
   begin
      ScreenHandler:=PEvalEventHook(evalEventsHooks[i]).SecondScrHandler;
   end;
   if (ScreenHandler<>nil) then
     try
       str:=E_STRING(text);
       TEvalStreamProc(ScreenHandler)(str,StrBufSize(str),PEvalEventHook(evalEventsHooks[i]).Data);
       strDispose(str);
     except
        result:=-1;
     end;
  end;

end;


{Fonction qui convertit un rinfo en string}
function cnv_rinfoTostr(rinfo:prinfo;const FDigit:integer=-1 ):string;
begin
  case rinfo.rtype of
  vt_integer:
         result:=Inttostr(rinfo.IntValue);
  vt_bool:
         begin
         if rinfo.BoolValue then
         result:='Oui'
         else
         result:='Non';
         end;
  vt_float:  begin  // msgbox('ggf','hjhj');
        if (FDigit<-37) or (FDigit>37) then
          result:=floattostr(rinfo.floatvalue) //floattostr(rinfo.IntValue);
        else
         result:=floattostr(roundTo(rinfo.floatvalue,FDigit)); //floattostr(rinfo.IntValue);

         end;
  vt_char:
         result:=rinfo.CharValue;
  vt_date:
         result:=datetostr(rinfo.floatvalue);
  end;

end;

{fonction qui permet de créer un tableau}
function array_create(PID:integer;name,group:Pgstring;access:TevalAccess):integer;
var
    varinfo:Prinfo;
    //arrayInfo:ParrayInfo;
begin
        new(varinfo);
        fillrinfo(varinfo);
        strcopy(varinfo.name,PevChar(name));
        varinfo.group:=E_STRING(group);
        varinfo.PID:=PID;
        varInfo.rtype:=vt_array;
        varinfo.heritedNameSpace:=E_STRING(varInfo.group);
        varinfo.access:=access;
        setvar(PID,varInfo);
        {new(arrayinfo);
        arrayinfo.name:=name;
        arrayinfo.group:=group;
        }
       // if arraylist=nil then arraylist:=Tlist.Create;
        //for i:=0 to arraylist.count-1 do

end;


{fonction qui permet d'obtenir un array}
function array_get(PID:integer;name,group:Pgstring):Prinfo;
var
  rinfo:Prinfo;
begin
  result:=nil;
  rinfo:=GetvarAdress(PID,name,group);
  if (rinfo.rtype=vt_array) then result:=rinfo;
end;
{fonction qui permet d'obtenir une valeur dans un tableau}
function array_getvalue(PID:integer;arr:Prinfo;group,key:pgstring):Prinfo;
var
  keyId,i:integer;
begin
  keyId:=-1;
  result:=nil;
  for i:=0 to high(arr.arrays) do
  begin
     //showmessage(tableau.arrays[i].name+'____'+keyname);
     if  (arr.arrays[i].name=key) then
     begin
        keyId:=i;
        //showmessage(tableau.arrays[i].name+'____'+keyname);
     end;
  end;
  if keyId<>-1 then   result:=arr.arrays[keyid];
end;

{fonction qui permet de definir des valeur d'un array}
function array_setvalue(PID:integer;arr:Prinfo;group,key:pgstring;value:Prinfo):integer;
var
  tableau:prinfo;
  keyname:string;
  keyId,i,intkey:integer;
  varinfo:Prinfo;
begin
  tableau:=arr;
  value.PID:=PID;
  keyId:=-1;
  keyname:=key;
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
     keyname:=tableau.arrays[keyid].name;
     //tableau.arrays[keyid]^:=value^;
     rinfoCopy(tableau.arrays[keyid],value);
     strcopy(tableau.arrays[keyid].name,PevChar(keyname));
end;
{fonction qui permet de supprimer un element du tableau
code exporté de TList.delete des composants vcl}
function array_deleteValue(PID:integer;arr:Prinfo;key:Pgstring):integer;
var
  Temp: Pointer;
  i,Index,Fcount,KeyId:integer;
begin
  keyId:=-1;
  for i:=0 to high(arr.arrays) do
  begin
     //showmessage(tableau.arrays[i].name+'____'+keyname);
     if  (arr.arrays[i].name=key) then
     begin
        keyId:=i;
        //showmessage(tableau.arrays[i].name+'____'+keyname);
     end;
  end;
  index:=keyId ;
  Fcount:=high(arr.arrays)+1;
  if (Index >= 0) or (Index< FCount) then
  begin

    //Temp := Items[Index];
    Dec(FCount);
    if Index < FCount then

      System.Move(arr.arrays[Index + 1], arr.arrays[Index],
        (FCount - Index) * SizeOf(Pointer));
  end;


end;

{function qui permet de supprimer un tableau}
function array_delete(PID:integer;name,group:Pgstring):integer;
var
    varinfo:Prinfo;
begin
       result:= unsetvar(PID,name,group);
end;
{function qui permet de faire une copie conforme d'un tableau}
function array_copy(PID:integer;source,dest:pgstring):integer;
var
    varinfo:Prinfo;
begin
        {a revoir}
end;

{function qui permet d'avoir la postion actuelle de l'erreur dans EpInfo avec précésion
26.avril 2011}
function GetEpStrErrPos(Epstr:string;index:integer):integer;
var
  gar:strarr;
  i:integer;
  str:string;
begin
 try
     gar:=EpParse(Epstr,false);
     for i:=0 to (index)  do str:=str+gar[i] ; Result:=length(str);
 except
     result:=0;
 end;

end;

{fonction qui permet d'ajouter un type}
function addtype(PID:integer;ctype:PclassType):integer;
begin
  if typelist=nil then typelist.Create;
  ctype.PID:=PID;
  typelist.Add(ctype);
  result:=0;
end;
{fonction qui permet de supprimer un type}
function deletetype(PID:integer;name:string;group:string):integer;
var
  i:integer;
begin
  if typelist=nil then typelist:=Tlist.Create;
  for i:=0  to typelist.Count-1 do
  if (PclassType(typelist[i]).name=name) and (PclassType(typelist[i]).ParentNamespace=group) then
  if CanAccessProc(PclassType(typelist[i]).PID,PID)                                         then
  begin
    typelist.Delete(i);
    result:=0;
    break;
  end;
end;
{fonction qui permet d'avoir des infos sur une classe}
function GetClasstypeInfo(PID:integer;name,group:string;rctype:PclassType):integer;
var
  i:integer;
begin
  for i:=0  to typelist.Count-1 do
  if (PclassType(typelist[i]).name=name) and (PclassType(typelist[i]).ParentNamespace=group) then
  if CanAccessProc(PclassType(typelist[i]).PID,PID)                                          then
  begin
    rctype^:=PclassType(typelist[i])^;
    result:=0;
    break;
  end;

end;
{fonction qui permet de savoir si deux classes sont compatible}
function checkClassCompatible(PID:integer;class1,class2:string):boolean;
begin
  result:=false;
  if not result then  result:=IsChildNamespace(PID,class1,class2);
  if not result then  result:=IsChildNamespace(PID,class2,class1);

end;

function checkClassInstance(PID:integer;instance1,instance2:string):integer;
var
  ns1,ns2:integer;
  compatible:boolean;
begin


    result:=-1;
    ns1:=IndexFromNamespace(instance1,PID);
    ns2:=IndexFromNamespace(instance2,PID);
    if PScrInfo(namespacelist[ns1])._type=scr_class_instance then
    begin
      compatible:=CheckClassCompatible(PID,PScrInfo(namespacelist[ns1]).heritedNameSpace,PScrInfo(namespacelist[ns2]).heritedNameSpace);
      if compatible then result:=0 else result:=-1;
    end;
end;
function CheckClassInstanceType(PID:integer;instance,ctypeName,parentNs:string):integer;
var
  ctype:PclassType;
  compatible:boolean;
  nsId:integer;
begin
  new(ctype);
  nsId:=IndexFromNamespace(instance,PID);
  GetClassTypeInfo(PID,ctypename,ParentNs,ctype);
  compatible:=CheckClassCompatible(PID,ctype.classNs,PScrInfo(namespacelist[nsID]).heritedNameSpace);
  if compatible then  result:=0 else result:=-1;
  dispose(ctype);
end;
{fonction qui permet de copier une instance vers une autre}
function InstanceCopy(PID:integer;source,dest:string):integer;
begin
  result:=ns_varclone(PID,source,dest,false,clmClassInstance);
end;
{fonction qui permet de clonner une instance de classe

result=namespace de la nouvelle instance(clone)
}
function InstanceClone(PID:integer;instance,parent:string):string;
var
  nsid:integer;
  scr:PscrInfo;
  NewNs:string;
begin
  nsid:=IndexFromNamespace(instance,PID);
  if PscrInfo(namespacelist[nsid])._type<>scr_class_instance then exit;
  new(scr);
  fill_scr(scr,parent,PID);
  NewNs:=scr.Name;
  scr^:= PscrInfo(namespacelist[nsid])^; {fait une copy conforme}
  scr.Name:=NewNs;
  scr.parent:=parent;
  addNamespace(PID,scr,'',false);
  ns_varClone(PID,instance,newNs,false,clmClassInstance);
  ns_functionClone(PID,instance,NewNs,false,clmClassInstance);
  result:=NewNs
end;

{fonction qui permet de comparer deux instances}
function InstancesCompare(PID:integer;instance1,instance2:string):integer;
var
  nsId1,nsId2:integer;
  r:boolean;
  i:integer;
begin
  result:=-1;
  nsId1:=IndexFromNamespace(instance1,PID);
  nsId2:=IndexFromNamespace(instance2,PID);
  if (nsId1=-1)  or (nsId2=-1) then exit;
  r:=PscrInfo(namespacelist[nsId1]).heritedNameSpace=PscrInfo(namespacelist[nsId2]).heritedNameSpace;
  {TO DO: ajouter un code pour comparer toute les variables entre les 2 namespace}
  

  if r then   result:=0  else result:=-1;

end;

function class_getRealName(PID:integer;className,namespace:string):string;
var
  str:string;
begin
  str:='';
  if copy(namespace,Length(namespace)-1,1)<>'.' then str:='.';
  result:=format('%s%s%s',[namespace,str,className]);
end;
{fonction qui permet d'ajouter une classe}
function class_add(PID:integer;classname,namespace,extented:string):integer;
var
  scr:PscrInfo;
begin

  scr.Name:=class_getRealName(PID,classname,namespace);
  if indexFromNameSpace(scr.Name,PID)<>-1 then
  begin
    showmessage('Error déclaring classe name:'+ClassName);
  end;
  new(scr);
  scr.Name:=class_getRealName(PID,classname,namespace);
  scr.parent:=namespace;
  scr.heritedNameSpace:=extented;
  scr.silenceMode:=true;
  scr.defaultMemberAccess:=aPrivate;
  scr.scrFileName:='#nofile#';
  scr._type:=scr_class;
  result:=addNamespace(PID,scr,scr.Name,true);
end;
{fonction qui permet d'ajouter une methode a une classe}
function class_addmethode(PID:integer;classname,namespace:string;func:Pfunc):integer;
begin
    func.groupe:=E_STRING(class_GetRealName(PID,classname,namespace));
    result:=SetFunc(PID,func,func.name,func.groupe);
end;
{ajoute une propriété à une classe}
function class_addproperty(PID:integer;className,namespace:string;rinfo:prinfo):integer;
begin
  rinfo.group:=E_STRING(class_GetRealName(PID,classname,namespace));
  result:=Setvar(PID,rinfo,true);
end;
{supprimer une classe}
function class_delete(PID:integer;className,namespace:string):integer;
begin
   result:=deleteNamespace(PID,class_GetRealName(PID,classname,namespace),true);
end;
{supprime une propriété d'une classe}
function class_deleteProperty(PID:integer;className,namespace,propertyName:string):integer;
begin
  result:=UnsetVar(PID,PropertyName,class_GetRealName(PID,className,namespace));
end;
{supprime une methode d'une classe}
function class_deleteMethode(PID:integer;className,namespace,methodeName:string):integer;
begin
  result:=UnsetFunc(PID,methodeName,class_GetRealName(PID,className,namespace));
end;
{appelle de fonction virtuelles définit dans un module ou une application tiers}
{fonction qui permet d'appeler une fonction de type virtuel déclaré par une application ou un module}
function Call_v2func(func:Pfunc;args:PFuncSearchInfo;EpInfo:PepInfo;Eparr:Strarr;rinfo:Prinfo):integer;
var
  //ParamList:TList;
  a,i,nId:integer;
  scr:PscrInfo;
  retvar:Prinfo;
  tmpgroup:string;
  funcparam:Prinfo;
  SearchInfo:PFuncSearchInfo;
  ruInfo:PfuncRunningInfo;
  s_info:Pepinfo;


begin
  //showmessage('Call_vfunc');

  {Traitement des paramètres}
  searchinfo:=args;


  if args=nil then
  begin
     new(SearchInfo);
     SearchInfo.DeclarationArgList:=Tlist.Create;
     SearchInfo.ParamList:=Tlist.Create;
     //ParamList:=TList.Create;


     GetArgInfo(EPInfo.PID,func,SearchInfo.DeclarationArgList);
     if EvalArgs(SearchInfo.ParamList,EpInfo,EParr)=0 then exit;

  end;


   if (GetScrInfotype(epInfo.PID,epinfo.group)=scr_class_instance) or (GetScrInfotype(epInfo.PID,epinfo.group)=scr_running_methode) then
  begin

    tmpgroup:=string(epInfo.group)+'._tmp_'+inttostr(lastNameSpaceId+1);
  end
  else
  begin
    tmpgroup:=string(func.groupe)+'._tmp_'+inttostr(lastNameSpaceId+1);
  end;
  inc(lastNamespaceId);
  //if EpInfo.ErrId<>E_none then    showmessage('error before vfunc');
  for  i:=0 to searchInfo.declarationArglist.count-1 do {01.05.2011 evite de confondre les type surtout quand il s'agit de integer et float}
  begin
    PParamInfo(searchInfo.paramlist[i]).rtype:= Prinfo(searchInfo.declarationArglist[i]).rtype;
  end;
  i:=SearchInfo.ParamList.Count-1;
  {transfert des paramètres de la function}
  while not i<0 do
  begin
    //showmessage('kjk');
    //showmessage('paramètr_   '+PParamInfo(searchinfo.DeclarationArgList[i]).name);
    New(funcParam);
    fillrinfo(funcParam);
    //funcParam^:=PParamInfo(SearchInfo.ParamList[i])^;
    rinfoCopy(funcParam,PParamInfo(SearchInfo.ParamList[i]));
    funcparam.name:=PParamInfo(SearchInfo.DeclarationArgList[i]).name;
    if assigned(funcparam.group) then strDispose(funcparam.group);
    funcparam.group:=E_STRING(tmpgroup);
    Setvar(EpInfo.PID,funcParam);

  dec(i);
  end;
  new(scr);
  (*{definition paramètre de retour de la fonction}

   new(retvar);
   FillRinfo(retvar);
   retvar.name:='result';
   retvar.group:=Pgchar(tmpgroup);
   retvar.rtype:=vt_none;
   //Setvar(EpInfo.PID,retvar);
   *)

    {traitement spécial classs_instance et runningMehode}
   if (GetScrInfotype(epInfo.PID, epInfo.group)=scr_class_instance)or (GetScrInfotype(epInfo.PID,epinfo.group)=scr_running_methode)  then
   begin
     scr.parent:=epInfo.group;
     scr.scrFileName:='#classmethode#'+string(func.groupe);
   end
   else
   begin
    scr.parent:=func.groupe;
    scr.scrFileName:='#parent#';
   end;
   scr.cmd:=-1;
   scr.error_id:=-1;
   scr.parent:=func.groupe;
   Scr.IncorporetedScript:=EpInfo.IncorporetedScript;
   scr.PID:=EpInfo.PID;
   scr.silenceMode:=true;
   scr.Name:=Pgstring(tmpgroup);
   scr.scrFileName:='#nofile#';
   AddNamespace(EpInfo.PID,scr,scr.Name,false);
   {function running information}
   new(ruInfo);
   ruInfo.paramCount:=searchInfo.ParamList.Count;
   ruInfo.group:=stralloc(length(tmpgroup)+1);
   strcopy(ruInfo.group,Pchar(tmpgroup));
   new(s_Info);
   fillEpInfo(s_info);
   //s_Info^:=Epinfo^;
   epInfoCopy(s_info,epInfo);
   if assigned(s_info.group) then strDispose(s_info.group);
   s_Info.group:=E_STRING(tmpgroup);
   {function executing}
   TepvFunc(func.pfunc)(s_info.PID,func,ruInfo,rinfo,s_Info);
   //showmessage(rinfo.CharValue);
   If s_info.ErrId<>-1 then  copyEpError(s_info,epInfo);
   {netoyage...}
   freeEpInfo(s_info);
   strDispose(ruInfo.group);
  
   dispose(ruInfo);
   deletenamespace(EpInfo.PID,tmpgroup,true);
   for i:=0 to  searchInfo.ParamList.Count-1 do
   begin
     freerInfo(searchInfo.paramList[i]);
   end;

   for i:=0 to  searchInfo.DeclarationArgList.Count-1 do
   begin
    //strDispose(Prinfo(searchInfo.DeclarationArgList[i]).CharValue);
    freerInfo(searchInfo.DeclarationArgList[i]);
   end;
   if args=nil then
   begin
      searchInfo.ParamList.Free;
      searchInfo.DeclarationArgList.Free;
   end;
   SetLength(tmpgroup,0);
   {fin netoyage}


end;
{fonction qui permet d'executer une fonction a partir des paramètres}
function RunFunction(name:string;EpInfo:PepInfo;paramlist:Tlist;fresult:Prinfo):integer;
var
  searchInfo:PfuncSearchInfo;
  i,Found:integer;
  ParamInfo,dresult:Prinfo;
  finfo:Pfunc;
begin
  new(searchInfo);
  new(finfo);
  fillfunc(finfo);
  searchInfo.ParamList:=paramlist;
  searchInfo.DeclarationArgList:=Tlist.Create;
  //for i:=0 to paramlist.Count-1 do showmessage(Prinfo(paramlist[i]).charvalue);
  Found:=getfuncEx(EpInfo.PID,name,EpInfo.group,finfo,SearchInfo);
  if (found=0)then
  begin
     {execution de la fonction}
      if finfo.ftype=ft_adress then
      call_afunc(finfo,searchinfo,EpInfo,nil,fresult);
      if finfo.ftype=ft_virtual then
      call_vfunc(finfo,searchinfo,EpInfo,nil,fresult);
      if finfo.ftype=ft_virtual2 then
      call_v2func(finfo,searchInfo,EpInfo,nil,fresult);
      epinfo.traited:=true;
      EpInfo.prev_traited:=pt_function;

  end
  else
     case found of
     -1:;{aucune fonction trouvée}
     -2:
        begin
        SignalError(EpInfo,EPInfo.x,E_FUNCTION_ARG,'too much argument for this fonction');
        epInfo.traited:=true;
        end ;
     -3:
        begin
          SignalError(EpInfo,EPInfo.x,E_FUNCTION_ARG,'incompatible arguments for this fonction');
          epInfo.traited:=true;
        end;
     -4:
        begin
          SignalError(EpInfo,EPInfo.x,E_FUNCTIOn_ARG,'There no overload function that can accept these arguments');
          epInfo.traited:=true;
        end;
     -5:
        begin
          SignalError(Epinfo,Epinfo.x,E_Personal,'Unable to acces to this element. Access right is set to private');
          epInfo.traited:=true;
        end;
     end;
   result:=found;
   {netoyage}
   searchInfo.DeclarationArgList.Free;
   dispose(searchInfo);
   freefunc(finfo);
   {fin netoyage}
end;

{fonction qui permet d'extraire le nom de l'instance a partir du namespace enfant}
function Instance_ExtractName(PID:integer;scrName:string):string;
var
  ns:string;
  nsId:integer;
begin
  nsId:=IndexFromNamespace(scrName,PID);
  showmessage(scrname);
  while(PscrInfo(namespacelist[nsId])._type<>scr_class_instance) and (nsId<>-1) do
  begin
    nsId:=IndexFromNamespace(PscrInfo(namespacelist[nsId]).Name,PID);
    if PscrInfo(namespacelist[nsId]).heritedNameSpace=PscrInfo(namespacelist[nsId]).Name then nsId:=-1;
  end;
  if nsId<>-1 then
  if PscrInfo(namespacelist[nsId])._type=scr_class_instance then  result:=PscrInfo(namespacelist[nsId]).Name;
end;

{fonction qui permet de connaître le namespace }
function IsClassMethode(PID:integer;func:Pfunc;classname:string):boolean;
var
  nsId:integer;
begin
 result:=func.groupe=className;
 //showmessage(classname);
 if not result then
 begin
   nsId:=IndexfromNamespace(className,PID);
   if (nsId<>-1) then
   if (PscrInfo(namespacelist[nsId])._type=scr_class) then
   result:=IsClassMethode(PID,func,PscrInfo(namespacelist[nsid]).heritedNameSpace);
 end;

end;
{fonction qui permet d'avoir le parent d'un scrInfo}
function scr_ExtractParent(PID:integer;ns:string):string;
var
  str:string;
  i:integer;
begin
   str:=ns;i:=0;
   //showmessage(str);
   while pos('.',str)>0 do
   begin
    i:=i+pos('.',str); str:=copy(str,i+1,length(str)-i);
   end;
   result:=copy(ns,1,i);
   if result[length(result)]<>'.' then result:=result+'.';
end;
{fonction qui permet d'avoir le type d'un scrinfo}
function scr_gettype(PID:integer;ns:string):Pscrtype;
begin
  result:=getScrInfotype(PID,ns);
end;


end.
