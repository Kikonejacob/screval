unit geval;

interface
uses classes,sysutils,forms,windows;

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
     ErrorParam:Pchar;
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
   TEvalStreamProc=function(text:pchar;buffSize:integer):integer;stdcall;
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
const Opstr='+;-;(;);*;/;&;<;>;=;";,;.;[;];:;'+'!;$;%,%;!; ;'';?>;<?;';

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

{Operation de text sur rinfo}
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
var
  libEval_Handle:Thandle;
  initEval:function:boolean;stdcall;

{fonction ,constantes,variables definition functions}
 GetFunc:function(PID:integer;funcname,group:pchar;rfunc:Pfunc):integer;stdcall;
 SetFunc:function(PID:integer;func:PFunc):integer;stdcall;
 Setvar:function(PID:integer;rvar:PvarInfo;EraseExisting:boolean):integer; stdcall;
 Getvar:function(PID:integer;name,group:pchar;rvar:PvarInfo):integer;stdcall;
 deleteVar:function(PID:integer;varstr,group:pchar):integer;stdcall;
 deleteFunc:function(PID:integer;name,group:pchar):integer;stdcall;
 GetConst:function(name,groupe:pchar;rconst:Pconstinfo):integer;stdcall;
 deletefuncs:function (PID:integer;group:pchar):integer;stdcall;
 deleteVars:function (PID:integer;group:pchar):integer;stdcall;


 fill_scr:function(scr:PscrInfo;parent:pchar;PID:integer):integer;stdcall;
 Fillrinfo:function(rinfo:prinfo):integer; stdcall;
{Eval Hook}
 SetEvalHook:function(Hook:PEvalEventHook):integer;stdcall;
 UnsetEvalHook:function(AppHandle:integer):integer;stdcall;

 ExpEvalEx:function(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;scr:PscrInfo):integer;stdcall;
 ExpEval:function(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;group:pchar):integer;stdcall;
{namespaces}
 AddReadyNamespace:function(name:pchar;AutoCreateParent:boolean;PID:integer):integer;stdcall;
 deleteNamespace:function(PID:integer;namespace:pchar;deleteChild:boolean):integer;stdcall;
 addScrDependency:function(PID:integer;namespace,dependency:pchar):integer;stdcall;
{rinfo manipulation}
 rtypeToStrEx:function(rinfo:Prinfo):pchar;stdcall;
 rtypeToStr:function(rtype:integer):pchar;stdcall;
 cnv_rinfoTostr:function(rinfo:prinfo;FDigit:integer):pchar;stdcall;
 isnumeric:function(gstr:pchar):boolean;stdcall;
 ConvertRinfoValueType:function(rinfo:Prinfo;rtype:integer;replacetype:boolean):boolean;stdcall;
{Array functions}
 array_setvalue:function (PID:integer;arr:Prinfo;group,key:pchar;value:Prinfo):integer;stdcall;
 array_deletevalue:function (PID:integer;arr:Prinfo;group,key:pchar):integer;stdcall;
 array_delete:function (PID:integer;name,group:pchar):integer;stdcall;
 array_create:function (PID:integer;name,group:Pchar;access:TevalAccess):integer;stdcall;
 array_get:function (PID:integer;name,group:pchar):Prinfo;stdcall;
 array_getvalue:function (PID:integer;arr:Prinfo;group,key:pchar):Prinfo;stdcall;
{
 {script and script file function}
 run_scr:function(PID:integer;hfile:pchar;parentscr:pchar;hookhandler:Thandle):integer;stdcall;
 ScriptEvalEx:function(text:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
 ScriptFileEval:function (filename:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
 EvalScriptFromFile:function(PID:integer;filepath,parentnamespace,buff:pchar;buffsize:integer;silenceMode:boolean):integer;stdcall;
{Eval Process}
 DeleteEvalProcess:function (PID:integer):boolean;stdcall;
 CreateEvalProcessEx:function (ProcessInfo:PevalProcessInfo):integer;stdcall;
 CreateEvalProcess:function (AppHandle:integer;locked:boolean):integer;stdcall;

 GetNamespaces:function(PID:integer;Parent:pchar;lister:pointer):boolean;stdcall;
 GetFuncs:function(PID:integer;group:pchar;lister:pointer):boolean;stdcall;
 vfunc_getvarAddress:function (PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;

 Getvars:function(PID:integer;group:pchar;lister:pointer):boolean;stdcall;
 {Memory management}
 _estrDispose:procedure (str:pchar); stdcall;
 _estrAlloc:function (size:integer):pchar; stdcall;
 _edispose:procedure (ptr:Pointer);stdcall;
 _enew:function (size:integer):pointer;stdcall;
 _estring:function (str:pchar;len:integer):pchar;stdcall;
 enew2:function (size:integer):pointer; stdcall;


 _newfunc:           function  :Pfunc; stdcall;
 _newepinfo:         function  :PepInfo; stdcall;
 _newrinfo:          function  :Prinfo; stdcall;
 _newEvalEventHook:  function  :PEvalEventHook;stdcall;
 
 _fillfunc:          procedure (func:pfunc);stdcall;
 _fillepinfo:         procedure (epInfo:PepInfo);stdcall;

 _freeEpInfo:        procedure(epInfo:PepInfo);stdcall;
 _freefunc:          procedure(func:Pfunc);stdcall;
 _freerinfo:         procedure(rinfo:prinfo);stdcall;


 getrInfoStr:procedure (rinfo:PrInfo;FDigit:integer;buff:pchar;buffSize:integer);stdcall;
 getfuncParam:function (PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;
 _rinfotext:function (rinfo:Prinfo;text:Pchar;len:integer;operation:integer):boolean; stdcall;
 _estrSize:function (str:pchar):integer; stdcall;



procedure enew(P:pointer;size:integer); stdcall;
procedure edispose(ptr:pointer);stdcall;
procedure estrDispose(str:pchar); stdcall;
function eStrAlloc(size:integer):pointer;stdcall;
function estrSize(str:pchar):integer;stdcall;


function newfunc:pfunc;
function newrinfo:Prinfo;
function newEpInfo:PepInfo;
function newEvalEventHook:PEvalEventHook;
procedure fillEpinfo(epInfo:PepInfo);
procedure fillfunc(func:pfunc);
procedure freerinfo(rinfo:Prinfo);
procedure freefunc(func:Pfunc);
procedure freeEpinfo(epInfo:PepInfo);
function E_STRING(str:string):pchar; overload;
function E_STRING(str:pchar):pchar; overload;
function   RINFO_TEXT(rinfo:Prinfo;text:Pchar;len:integer;operation:integer):boolean;
procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar);
procedure  RINFO_CATTEXT(rinfo:Prinfo;text:Pchar);

function EvalEp(PID:integer;Epstr:string;rinfo:prinfo;foruser,SilentMode:boolean;const group:string=''):integer;

function AddVirtualFunc2(PID:integer;name,params,group:string;rtype:integer;Access:TevalAccess;funcPtr:pointer):boolean;


function AddVariable(PID:integer;name,group:string;var value;rtype:integer;Access:TEvalAccess):boolean;
function AddPublicVariable(PID:integer;name,group:string;var value;rtype:integer):boolean;
function AddPrivateVariable(PID:integer;name,group:string;var value;rtype:integer):boolean;





{

type
TSCRIPT=class(Tobject)
private
  ePID:integer;
public
  constructor Create();
  function GetFunc(funcname,group:string;rfunc:Pfunc):integer;
  function SetFunc(func:PFunc):integer;
  function Setvar(rvar:PvarInfo):integer;
  function Getvar(name,group:string;rvar:PvarInfo):integer;
  function deleteVar(varstr,group:string):integer;
  function deleteFunc(name,group:string):integer;
  function GetConst(name,groupe:pchar;rconst:Pconstinfo):integer;
  function AddReadyNamespace(name:string;AutoCreateParent:boolean;):integer;
  function deleteNamespace(namespace:string;deleteChild:boolean):integer;
  function EvalScriptFromFile(filepath,parentnamespace,buff:pchar;buffsize:integer;silenceMode:boolean):integer;stdcall;
end;  }

procedure libEval_free;
function LibEval_loadEx(Libhandle:Thandle):integer;
function LibEval_load(name:pchar):integer;



const
   LibscrEval='libscreval.dll';
   libscrEvalW='libscrevalW.dll';
const
  FLOAT_ILLIMITED_DIGIT=-50;




implementation

function LibEval_loadEx(Libhandle:Thandle):integer;
  function assign_proc(var proc: FARPROC; name: pChar):integer;
  begin
    result:=0;
    proc := GetProcAddress(libEval_handle, name);
    if proc = nil then result := -1;
  end;

begin
  libEval_handle:=LibHandle;
  if libEval_handle = 0 then result:=-1
  else
  begin
    //libmysql_status := LIBMYSQL_READY;
    assign_proc(@initEval, 'initEval');
    assign_proc(@CreateEvalProcess, 'CreateEvalProcess');
    assign_proc(@CreateEvalProcessEx, 'CreatEvalProcessEx');
    assign_proc(@DeleteEvalProcess, 'DeleteEvalProcess');
    assign_proc(@UnsetEvalHook,'UnsetEvalHook');
    assign_proc(@SetEvalHook, 'SetEvalHook');
    assign_proc(@Fillrinfo, 'Fillrinfo');
    assign_proc(@fill_scr, 'fill_scr');
    assign_proc(@Getvar, 'Getvar');
    assign_proc(@Setvar, 'Setvar');
    assign_proc(@SetFunc, 'SetFunc');
    assign_proc(@GetFunc, 'GetFunc');
    assign_proc(@ScriptFileEval, 'ScriptFileEval');
    assign_proc(@EvalScriptFromFile, 'EvalScriptFromFile');
    assign_proc(@ExpEvalEx, 'ExpEvalEx');
    assign_proc(@ExpEval, 'ExpEval');
    assign_proc(@AddReadyNamespace, 'AddReadyNamespace');
    //assign_proc(@AddNamespace, 'AddNamespace');
    assign_proc(@DeleteVar, 'deleteVar');
    assign_proc(@DeleteFunc, 'deleteFunc');
    assign_proc(@deleteNamespace, 'deleteNamespace');
    assign_proc(@addScrDependency, 'addScrDependency');
    assign_proc(@GetConst, 'GetConst');
    assign_proc(@rtypeToStrEx, 'rtypeToStrEx');
    assign_proc(@rtypeToStr, 'rtypeToStr');
    assign_proc(@cnv_rinfoTostr, 'cnv_rinfoTostr');
    assign_proc(@isnumeric, 'isnumeric');
    assign_proc(@run_scr,'run_scr');
    assign_proc(@UnsetEvalHook,'UnsetEvalHook');
    assign_proc(@GetNamespaces,'GetNamespaces');
    assign_proc(@GetFuncs,'GetFuncs');
    assign_proc(@Getvars,'Getvars');
    assign_proc(@array_create,'array_create');
    assign_proc(@array_delete,'array_delete');
    assign_proc(@array_get,'array_get');
    assign_proc(@array_getvalue,'array_getvalue');
    assign_proc(@array_deletevalue,'array_deletevalue');
    assign_proc(@array_setvalue,'array_setvalue');

    assign_proc(@_estrAlloc,'_estrAlloc');
    assign_proc(@_edispose,'_edispose');
    assign_proc(@_enew,'_enew');
    assign_proc(@_estrDispose,'_estrDispose');

    assign_proc(@_newrinfo,'_newrinfo');
    assign_proc(@_newepinfo,'_newepinfo');
    assign_proc(@_newfunc,'_newfunc');
    assign_proc(@_newEvalEventHook,'_newEvalEventHook');

    assign_proc(@_freerinfo,'_freerinfo');
    assign_proc(@_freeepinfo,'_freeepinfo');
    assign_proc(@_freefunc,'_freefunc');

    assign_proc(@_fillepinfo,'_fillepinfo');
    assign_proc(@_fillfunc,'_fillfunc');

    assign_proc(@getrInfoStr,'getrInfoStr');
    assign_proc(@getfuncParam,'getfuncParam');
    assign_proc(@_estring,'_estring');
    assign_proc(@enew2,'enew2');
    assign_proc(@_rinfoText,'_rinfotext');
    assign_proc(@_estrSize,'_estrSize');
    assign_proc(@vfunc_getvarAddress,'vfunc_getvarAddress');
     assign_proc(@ConvertRinfoValueType,'ConvertRinfoValueType');
   //assign_proc(@_newfunc,'newfunc');
    //assign_proc(@_freefunc,'freefunc');


  end;


end;
function LibEval_load(name:pchar):integer;
begin
  libEval_free;
  {$IFDEF UNICODE}
  if name = nil then name :=libscrEvalW;{ a voir spécifier le path complet pour éviter les virus}
  {$ELSE}
  if name = nil then name :=libscrEval;{ a voir spécifier le path complet pour éviter les virus}
  {$ENDIF}

  libEval_handle := LoadLibrary(name);
  result:=LibEval_loadEx(libEval_Handle);
end;


procedure libEval_free;
begin
  if libEval_handle <> 0 then FreeLibrary(libEval_handle);
  libEval_handle := 0;
end;



procedure enew( P:pointer;size:integer); stdcall;
begin

   P:=_enew(size);
   //initialize(P);
end;
procedure edispose(ptr:pointer);stdcall;
begin
   _edispose(ptr);
end;
function eStrAlloc(size:integer):pointer;stdcall;
begin
   result:=_estrAlloc(size);
end;
{
function E_STRING(str:string):pchar;
var
  p:pchar;
begin
  p:=stralloc(length(str)+1);
  strcopy(p,pchar(str));
  result:=_estring(p,strlen(p)+1);
  strDispose(p);
end;
function E_STRING(str:pchar):pchar;
var
  p:pchar;
begin
  p:=stralloc(length(str)+1);
  strcopy(p,pchar(str));
  result:=_estring(p,strlen(p)+1);
  strDispose(p);
end;      }
function E_STRING(str:string):pchar;
begin
  result:=_estring(Pchar(str),length(str)+1);
end;

function E_STRING(str:Pchar):pchar;
begin
  result:=_estring(str,strlen(str)+1);
end;


procedure RINFO_STRING(rinfo:Prinfo;str:string);
begin
   estrDispose(rinfo.CharValue);
   rinfo.CharBuffSize:=length(str)+1;
   rinfo.CharValue:=_estring(Pchar(str),length(str));
end;

procedure estrDispose(str:pchar); stdcall;
begin
  _estrDispose(str);
end;

procedure  fillfunc(func:pfunc);
begin
  _fillfunc(func);
end;


procedure fillEpinfo(epInfo:PepInfo);
begin
  _fillepinfo(epInfo);
end;

function newEpInfo:PepInfo;
begin
  result:=_newepinfo;
 // result:=enew2(sizeof(depInfo));
end;

function newEvalEventHook:PEvalEventHook;
begin
  result:=_newEvalEventHook;
 // result:=enew2(sizeof(depInfo));
end;
{function newfunc:pfunc;
begin
   _newfunc;
end;
 }
function newrinfo:Prinfo;
begin
  result:=_newrinfo;
  //result:=enew2(sizeof(drinfo));
end;

procedure freeEpinfo(epInfo:PepInfo);
begin
  _freeepinfo(epInfo);
  //eDispose(epInfo);
end;

procedure freefunc(func:Pfunc);
begin
// _freefunc(func);
 eDispose(func);
end;
procedure freerinfo(rinfo:Prinfo);
begin
  _freerinfo(rinfo);
  // eDispose(rinfo);
end;

function newfunc:pfunc;
begin
   //result:=_newfunc;
  result:=Pfunc(enew2(sizeof(dfunc)));
end;

function estrSize(str:pchar):integer;stdcall;
begin
  result:=_estrSize(str);
end;
function   RINFO_TEXT(rinfo:Prinfo;text:Pchar;len:integer;operation:integer):boolean;
begin
   result:=_rinfoText(rinfo,text,len,operation);
end;
procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar);
begin
  RINFO_TEXT(rinfo,text,StrLen(text)+1,TextOperation_copy);
end;
procedure  RINFO_CATTEXT(rinfo:Prinfo;text:Pchar);
begin
   RINFO_TEXT(rinfo,text,StrLen(text)+1,TextOperation_cat);
end;

{Fonction qui permet d'évaluer une expression}
function EvalEp(PID:integer;Epstr:string;rinfo:prinfo;foruser,SilentMode:boolean;const group:string=''):integer;
var
  EpInfo:Pepinfo;
  gar:strarr;
begin
  //new(Epinfo);
  epinfo:=newEpInfo;
  fillEpinfo(epInfo);
  epInfo.group:=E_STRING(group);
  epInfo.cmd:=worknone;
  epInfo.BreakChar:='';
  epInfo.ForUser:=foruser;
  epInfo.ErrId:=vt_none;
  epInfo.PID:=PID;
  epInfo.silentMode:=SilentMode;
  //epInfo.silentMode:=false;
  if rinfo=nil then exit;
  //showmessage(rinfo.group);
  //showmessage(group);
  //showmessage(epinfo.group);
  //showmessage(str);
  expEval(pchar(Epstr),strlen(pchar(Epstr))+2,rinfo,true,EpInfo,pchar(group));
//  dispose(EpInfo);
  result:=EpInfo.ErrId;{si epInfo.errid<>-1 alors ya erreur}
  freeEpInfo(epInfo);
  //Dispose(EpInfo);
end;

function AddVirtualFunc2(PID:integer;name,params,group:string;rtype:integer;Access:TevalAccess;funcPtr:pointer):boolean;
var
  func:Pfunc;
begin
  func:=newfunc;
  fillfunc(func);
  strcopy(func.name,pchar(name));
  func.ftype:=ft_virtual2;
  func.rtype:=vt_none;
  func.groupe:=E_STRING(group);
  func.access:=Access;
  func.params:=E_STRING(Params);
  func.pfunc:=funcPtr;
  SetFunc(ROOT_PID,func);
end;


function AddVariable(PID:integer;name,group:string;var value;rtype:integer;Access:TEvalAccess):boolean;
var
  rinfo:PRinfo;
begin
  rinfo:=newrinfo;fillrinfo(rinfo);
  rinfo.access:=Access;
  rinfo.name:='recuid';
  rinfo.group:=E_STRING(group);
  rinfo.rtype:=rtype;
  with rinfo^ do
  case rinfo.rtype of
  VT_INTEGER:
      begin
         IntValue:=Integer(value);
         FloatValue:=Integer(value);
      end;
  VT_NUMERIC,VT_FLOAT:
     begin
        IntValue:=Round(Double(value));
        FloatValue:=Double(value);
     end;
  VT_BOOL:
     begin
       BoolValue:=Boolean(value);
     end;
  VT_CHAR:
     begin
       RINFO_COPYTEXT(rinfo,pchar(Value));
     end;
  end;
  Setvar(PID,rinfo,true);
end;


function AddPublicVariable(PID:integer;name,group:string;var value;rtype:integer):boolean;
begin
  AddVariable(PID,name,group,value,rtype,aPublic);
end;

function AddPrivateVariable(PID:integer;name,group:string;var value;rtype:integer):boolean;
begin
  AddVariable(PID,name,group,value,rtype,aPublic);
end;




end.
