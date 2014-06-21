unit main;

{Ici sont contenu la liste des fonctions a exporter}

interface

uses eval,script,scr_reg_eval,regeval,sysutils,dialogs,classes,alloc,eval_extra;

{fonction ,constantes,variables definition functions}
function GetFunc(PID:integer;funcname,group:pchar;rfunc:Pfunc):integer;stdcall;
function SetFunc(PID:integer;func:PFunc):integer;stdcall;
function Setvar(PID:integer;rvar:PvarInfo;EraseExisting:boolean):integer; stdcall;
function Getvar(PID:integer;name,group:pchar;rvar:PvarInfo):integer;stdcall;
function deleteVar(PID:integer;varstr,group:pchar):integer;stdcall;
function deleteFunc(PID:integer;name,group:pchar):integer;stdcall;
function deletefuncs(PID:integer;group:pchar):integer; stdcall;
function deleteVars(PID:integer;group:pchar):integer; stdcall;

function GetConst(name,groupe:pchar;rconst:Pconstinfo):integer;stdcall;

function fill_scr(scr:PscrInfo;parent:pchar;PID:integer):integer;stdcall;
function initEval:boolean;stdcall;
function Fillrinfo(rinfo:prinfo):integer; stdcall;
{Eval Hook}
function SetEvalHook(Hook:PEvalEventHook):integer;stdcall;
function UnsetEvalHook(AppHandle:integer):integer;stdcall;

function ExpEvalEx(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;scr:PscrInfo):integer;stdcall;
function ExpEval(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;group:pchar):integer;stdcall;
{namespaces}
//function AddNamespace(scr:PscrInfo;name:pchar;AutoCreateParent:boolean;PID:integer):integer;stdcall;
function AddReadyNamespace(name:pchar;AutoCreateParent:boolean;PID:integer):integer;stdcall;
function deleteNamespace(PID:integer;namespace:pchar;deleteChild:boolean):integer;stdcall;
function addScrDependency(PID:integer;namespace,dependency:pchar):integer;stdcall;
{rinfo manipulation}
function rtypeToStrEx(rinfo:Prinfo):pchar;stdcall;
function rtypeToStr(rtype:integer):pchar;stdcall;
function cnv_rinfoTostr(rinfo:prinfo;FDigit:integer):pchar;stdcall;
function isnumeric(gstr:pchar):boolean;stdcall;
function ConvertRinfoValueType(rinfo:Prinfo;rtype:integer;replacetype:boolean):boolean; stdcall;

{Array functions}
function array_setvalue(PID:integer;arr:Prinfo;group,key:pchar;value:Prinfo):integer;stdcall;
function array_deletevalue(PID:integer;arr:Prinfo;group,key:pchar):integer;stdcall;
function array_delete(PID:integer;name,group:pchar):integer;stdcall;
function array_create(PID:integer;name,group:Pchar;access:TevalAccess):integer;stdcall;
function array_get(PID:integer;name,group:pchar):Prinfo;stdcall;
function array_getvalue(PID:integer;arr:Prinfo;group,key:pchar):Prinfo;stdcall;
{script and script file function}
function run_scr(PID:integer;hfile:pchar;parentscr:pchar;hookhandler:Thandle):integer;stdcall;
function ScriptEvalEx(text:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
function ScriptFileEval(filename:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
function EvalScriptFromFile(PID:integer;filepath,parentnamespace,buff:pchar;buffsize:integer;silenceMode:boolean):integer;stdcall;
{Eval Process}
function DeleteEvalProcess(PID:integer):boolean;stdcall;
function CreateEvalProcessEx(ProcessInfo:PevalProcessInfo):integer;stdcall;
function CreateEvalProcess(AppHandle:integer;locked:boolean):integer;stdcall;


function GetNamespaces(PID:integer;Parent:pchar;lister:pointer):boolean;stdcall;
function GetFuncs(PID:integer;group:pchar;lister:pointer):boolean; stdcall;
function Getvars(PID:integer;group:pchar;lister:pointer):boolean;stdcall;

function class_deleteProperty(PID:integer;className,namespace,propertyName:pchar):integer;stdcall;
function class_deleteMethode(PID:integer;className,namespace,methodeName:pchar):integer;stdcall;
function class_delete(PID:integer;className,namespace:pchar):integer;stdcall;
function class_addproperty(PID:integer;className,namespace:pchar;rinfo:prinfo):integer;stdcall;
function class_addmethode(PID:integer;classname,namespace:pchar;func:Pfunc):integer;stdcall;
function class_add(PID:integer;classname,namespace,extented:pchar):integer; stdcall;



{memory management}
function _enew(size:integer):pointer; stdcall;
function enew2(size:integer):pointer; stdcall;

procedure _edispose(ptr:pointer); stdcall;
function _estrAlloc(size:integer):pointer;stdcall;
procedure _estrDispose(str:pchar); stdcall;

function _estring(str:pchar;len:integer):pchar;stdcall;

function  _newfunc:Pfunc; stdcall;
function  _newepinfo:PepInfo; stdcall;
function  _newrinfo:Prinfo; stdcall;

procedure _fillfunc(func:pfunc);stdcall;
procedure _fillepinfo(epInfo:PepInfo);stdcall;

procedure _freeepinfo(epInfo:PepInfo);stdcall;
procedure _freefunc(func:Pfunc);stdcall;
procedure _freerinfo(rinfo:prinfo);stdcall;



procedure getrInfoStr(rinfo:PrInfo;FDigit:integer;buff:pchar;buffSize:integer);stdcall;
function getfuncParam(PID:integer;name:pchar;epInfo:pointer):Prinfo;stdcall;
function vfunc_getvarAddress(PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;

function _rinfotext(rinfo:Prinfo;text:Pchar;len:integer;operation:integer):boolean;stdcall;
function _estrSize(str:pchar):integer; stdcall;
function _newEvalEventHook:PEvalEventHook; stdcall;









implementation
{ici on ajoute a eval.initEval reg_scr_opt}
function initEval:boolean;stdcall;
begin
  result:=eval.initEval;
  reg_scr_op();
end;
function ScriptEvalEx(text:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
begin
  result:=script.scr_evalEx(text,scr,PID)
end;

function ScriptFileEval(filename:pchar;scr:PscrInfo;PID:integer):integer;stdcall;
begin
  result:=script.loadcodeEx(filename,'',scr);
end;

function GetFunc(PID:integer;funcname,group:pchar;rfunc:Pfunc):integer;stdcall;
begin
  result:=eval.GetFunc(PID,funcname,group,rfunc);
end;

function fill_scr(scr:PscrInfo;parent:pchar;PID:integer):integer;stdcall;
begin
 result:=eval.fill_scr(scr,parent,PID);
end;

function Getvar(PID:integer;name,group:pchar;rvar:PvarInfo):integer;stdcall;
begin
 result:=eval.Getvar(PID,name,group,rvar);
end;

function Setvar(PID:integer;rvar:PvarInfo;EraseExisting:boolean):integer; stdcall;
var
  varinfo:Pvarinfo;
begin
{  new(varinfo);
  varinfo.IntValue:=rvar.IntValue;
  varinfo.CharValue:=rvar.CharValue;
  varinfo.BoolValue:=rvar.BoolValue;
  varinfo.rtype:=rvar.rtype;
  varinfo.ErrId:=rvar.ErrId;
  varinfo.floatvalue:=rvar.floatvalue;
  varinfo.pt:=rvar.pt;
  varinfo.name:=rvar.name;
  varinfo.group:=rvar.group;
  varinfo.arrays:=rvar.arrays;
  varinfo.access:=rvar.access;
  varinfo.heritedNameSpace:=rvar.heritedNameSpace;
  varinfo.isReference:=rvar.isReference;
  varinfo.reference:=rvar.reference;
  varinfo.DefaultValue:=rvar.DefaultValue;
  varinfo.key:=rvar.key;
  varinfo.PID:=PID;  //attention
  result:=eval.Setvar(varinfo.PID,varinfo,EraseExisting);
  }
  result:=eval.Setvar(PID,rvar,EraseExisting);
end;

function SetFunc(PID:integer;func:PFunc):integer;stdcall;
var
  name:pchar;
begin
  name:=stralloc(256);
  strcopy(name,func.name);
  if (not(assigned(func.groupe)))           then  func.groupe:=E_STRING('');
  if (not(assigned(func.params)))           then  func.params:=E_STRING('');
  if (not(assigned(func.heritedNameSpace))) then  func.heritedNameSpace:=E_STRING('');

  result:=eval.SetFunc(PID,func,name,func.groupe);
  strdispose(name);
end;

function EvalScriptFromFile(PID:integer;filepath,parentnamespace,buff:pchar;buffsize:integer;silenceMode:boolean):integer;stdcall;
var
  scr:Pscrinfo;
begin
  result:=-1;
  //scr.silenceMode:=false;
  scr:=script.EvalScriptFromFile(PID,filepath,false,parentnamespace);
  if scr<>nil then
  begin
    if buff<>nil then  strLcopy(buff,pchar(scr.name),buffSize);
    result:=0;
 end;
 scr:=nil;
end;

function Fillrinfo(rinfo:prinfo):integer; stdcall;
begin
  result:=eval.Fillrinfo(rinfo);
end;

function SetEvalHook(Hook:PEvalEventHook):integer;stdcall;
begin
  result:=eval.SetEvalHook(hook);
end;
function UnsetEvalHook(AppHandle:integer):integer;stdcall;
begin
 result:=eval.UnSetEvalHook(AppHandle);
end;

function CreateEvalProcessEx(ProcessInfo:PevalProcessInfo):integer;stdcall;
begin
   result:=eval.CreatEvalProcess(ProcessInfo);
end;
function CreateEvalProcess(AppHandle:integer;locked:boolean):integer;stdcall;
var
  eProcess:PevalProcessinfo;
begin
   new(eProcess);
   eProcess.AppHandle:=AppHandle;
   eProcess.Locked:=locked;
   result:=eval.CreatEvalProcess(eProcess);
end;

function DeleteEvalProcess(PID:integer):boolean;stdcall;
begin
   result:=eval.DeleteEvalProcess(PID);
end;

function ExpEvalEx(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;scr:PscrInfo):integer;stdcall;
var
  str:pchar;
begin
  str:=stralloc(lstrSize);
  strlcopy(str,epstr,lstrsize);
  result:=eval.scr_EvalEp(EpStr,rinfo,forUser,Epinfo,scr)
end;
{Evalue une expression}
function ExpEval(Epstr:pchar;lstrSize:integer;rinfo:prinfo;forUser:boolean;EpInfo:PepInfo;group:pchar):integer;stdcall;
var
  scr:PscrInfo;
  str:pchar;
begin
  try
  scr:=PscrInfo(namespaceList[IndexOfNameSpace(group,EpInfo.PID)]);
  except
    scr:=nil;
    showmessage(format('unable to find namespace%s',[group])) ;
  end;
  {$IFDEF DEBUG_MODE}
   scr.silenceMode:=false;
   epInfo.silentMode:=false;
  {$ENDIF}
  //showmessage('kjk');
  str:=stralloc(lstrSize);
  strlcopy(str,epstr,lstrSize);
  //showmessage(epstr);
  if rinfo=nil then showmessage('rinfo is nil');
  if epinfo=nil then showmessage('epinfo is nil');
  //showmessage(epinfo.group);
  result:=eval.scr_EvalEp(Str,rinfo,forUser,Epinfo,scr);
  Strdispose(str);
end;

function AddNamespace(scr:PscrInfo;name:pchar;AutoCreateParent:boolean;PID:integer):integer;stdcall;
begin
  result:=eval.AddNamespace(PID,scr,name,AutoCreateParent);
end;
function AddReadyNamespace(name:pchar;AutoCreateParent:boolean;PID:integer):integer;stdcall;
var
  scr:PscrInfo;
begin
  new(scr);
  fill_scr(scr,'',PID);
  scr.Name:=name;
  //scr.silenceMode:=false;
  result:=eval.AddNamespace(PID,scr,name,AutoCreateParent);
end;

function deleteVar(PID:integer;varstr,group:pchar):integer;stdcall;
begin
  result:=eval.UnsetVar(PID,varStr,group);
end;
function deleteFunc(PID:integer;name,group:pchar):integer;stdcall;
begin
  result:=eval.UnsetFunc(PID,name,group) ;
end;
function deletefuncs(PID:integer;group:pchar):integer;stdcall;
begin
  result:=eval.deletefuncs(PID,group);
end;

function deleteVars(PID:integer;group:pchar):integer;stdcall;
begin
  result:=eval.deleteVars(PID,group);
end;

function deleteNamespace(PID:integer;namespace:pchar;deleteChild:boolean):integer;stdcall;
begin
  result:=eval.deleteNamespace(PID,namespace,deleteChild);
end;

function addScrDependency(PID:integer;namespace,dependency:pchar):integer;stdcall;
begin
  result:=AddScrDependency(PiD,namespace,dependency);
end;

function GetConst(name,groupe:pchar;rconst:Pconstinfo):integer;stdcall;
begin
  result:=eval.GetConst(name,groupe,rconst);

end;
function rtypeToStrEx(rinfo:Prinfo):pchar;stdcall;
var
  str:string;
begin
 // new(result);
  str:=eval.rtypeToStrEx(rinfo);
  result:=stralloc(strbufsize(pchar(str)));
  strcopy(result,pchar(str));
end;
function cnv_rinfoTostr(rinfo:Prinfo;FDigit:integer):pchar;stdcall;
var
  str:string;
begin
  //new(result);
  str:=eval.cnv_rinfoTostr(rinfo,FDigit);
//  showmessage(str);
  //if str='6' then showmessage('rinfo to 6:'+string(rinfo.CharValue));
  result:=stralloc(length(str)+1);
  strcopy(result,pchar(str));
  //result:=0;
end;
{identique a cnv_rinfoTostr}
procedure getrInfoStr(rinfo:PrInfo;FDigit:integer;buff:pchar;buffSize:integer);stdcall;
begin
  strLcopy(buff,Pchar(eval.cnv_rinfoToStr(rinfo,Fdigit)),buffSize);
end;

function rtypeToStr(rtype:integer):pchar;stdcall;
var
  str:string;
begin
  //new(result);
  str:=eval.rtypeToStr(rtype);
  result:=stralloc(256) ;
  strcopy(result,pchar(str));
end;
function isnumeric(gstr:pchar):boolean;stdcall;
begin
  result:=eval.isnumeric(gstr);
end;
function GetNewNameSpaceStr:string;
begin
end;

function array_create(PID:integer;name,group:Pchar;access:TevalAccess):integer;stdcall;
begin
  result:=eval.array_create(PID,name,group,access);
end;
function array_setvalue(PID:integer;arr:Prinfo;group,key:pchar;value:Prinfo):integer;stdcall;
begin
  result:=eval.array_setvalue(PID,arr,group,key,value);
end;


function array_get(PID:integer;name,group:pchar):Prinfo;stdcall;
begin
  result:=eval.array_get(PID,name,group);
end;
function array_getvalue(PID:integer;arr:Prinfo;group,key:pchar):Prinfo;stdcall;
begin
  result:=eval.array_getvalue(PID,arr,group,key);
end;

function array_deletevalue(PID:integer;arr:Prinfo;group,key:pchar):integer;stdcall;
begin
  result:=eval.array_deleteValue(PID,arr,key);
end;

function array_delete(PID:integer;name,group:pchar):integer;stdcall;
begin
  result:=eval.array_delete(PID,name,group);
end;

{function standart utilisée pour appeler un script dans un fichier:: Avervoir pour le hookHandler}
function run_scr(PID:integer;hfile:pchar;parentscr:pchar;hookhandler:Thandle):integer;stdcall;
var
   startText:string;
   Lines:TStringList;
   str:string;
   lastpos:integer;
   scr:PscrInfo;
begin
   Lines:=TStringList.create;
   //showmessage(hfile);
   lines.LoadFromFile(hfile);
   str:=Lines.Text;
   SetEvalHook(@hookhandler);
   if pos('<?',str)<pos('?>',str) then
   begin
      lastpos:=pos('<?',str)+2;
      startText:=copy(str,1,pos('<?',str)-1);
      //showmessage(str);
      TEvalStreamProc(hookHandler)(pchar(starttext),length(starttext)+1,nil);
    end;
    //scriptFileEval(hfile)

     new(scr);
     Fill_scr(scr,parentscr,PID);
     scr.Name:='';{sera automatiquement defini}
     scr.parent:=parentscr;
     scr.silenceMode:=true;
     if LoadCodeEx(hfile,scr.parent,scr)=-1 then
     msgbox(format('can not load file "%s"',[hfile]));

    script.EvalScriptFromFile(PID,hfile,'');
end;

function GetNamespaces(PID:integer;Parent:pchar;lister:pointer):boolean;stdcall;
begin
  result:=eval.GetNamespaces(PID,parent,lister);
end;
function GetFuncs(PID:integer;group:pchar;lister:pointer):boolean;stdcall;
begin
 result:=eval.GetFuncs(PID,group,lister);
end;
function Getvars(PID:integer;group:pchar;lister:pointer):boolean;stdcall;
begin
 result:=eval.Getvars(PID,group,lister);
end;
function class_add(PID:integer;classname,namespace,extented:pchar):integer; stdcall;
begin
  result:=eval.class_add(PID,classname,namespace,extented);
end;
function class_addmethode(PID:integer;classname,namespace:pchar;func:Pfunc):integer;stdcall;
begin
  result:=eval.class_addmethode(PID,classname,namespace,func);
end;
function class_addproperty(PID:integer;className,namespace:pchar;rinfo:prinfo):integer;stdcall;
begin
  result:=eval.class_addproperty(PID,classname,namespace,rinfo);
end;
function class_delete(PID:integer;className,namespace:pchar):integer;stdcall;
begin
  result:=eval.class_delete(PID,classname,namespace);
end;
function class_deleteMethode(PID:integer;className,namespace,methodeName:pchar):integer;stdcall;
begin
  result:=eval.class_deleteMethode(PID,className,namespace,methodeName);
end;
function class_deleteProperty(PID:integer;className,namespace,propertyName:pchar):integer;stdcall;
begin
  result:=eval.class_deleteProperty(PID,classname,namespace,propertyName);
end;


function _enew(size:integer):pointer; stdcall;
begin
   result:=alloc.enew(size);
end;
procedure _edispose(ptr:pointer);stdcall;
begin
  alloc.edispose(ptr);
end;
function _eStrAlloc(size:integer):pointer;stdcall;
begin
   result:=alloc.estrAlloc(size);
end;

procedure _estrDispose(str:pchar); stdcall;
begin
  alloc.estrDispose(str);
end;

function _estring(str:pchar;len:integer):pchar;
begin
  result:=alloc.estring(str,len);
end;


{External memory relations}


function _newfunc:Pfunc; stdcall;
begin
  result:=eval_extra.newfunc;
end;

function _newrinfo:Prinfo; stdcall;
begin
  result:=eval_extra.newrinfo;
end;

function _newepinfo:PepInfo;stdcall;
begin
  result:=eval_extra.newEpInfo;
end;

function _newEvalEventHook:PEvalEventHook; stdcall;
begin
  result:=eval_extra.newEvalEventHook;
end;

procedure _fillfunc(func:pfunc);stdcall;
begin
  eval_extra.FillFunc(func);
end;

procedure _fillepinfo(epInfo:PepInfo); stdcall;
begin
  eval_extra.FillEpInfo(epInfo);
end;

procedure _freerinfo(rinfo:prinfo);stdcall;
begin
  eval_extra.freerinfo(rinfo);
end;

procedure _freefunc(func:Pfunc);stdcall;
begin
  eval_extra.freefunc(func);
end;
procedure _freeepinfo(epInfo:PepInfo);stdcall;
begin
  eval_extra.freeEpInfo(epInfo);
end;




{obtient un les paramètres d'une fonction}
function GetFuncParam(PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;
begin
  result:=eval.GetvarAdress(PID,name,Pepinfo(epInfo).group)
end;

{premet a une fonction virtuelle d'acceder aux variables de son namespace}
function vfunc_getvarAddress(PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;
begin
  result:=eval.GetvarAdress(PID,name,Pepinfo(epInfo).group)
end;

function enew2(size:integer):pointer; stdcall;
begin
  getmem(result,size);
end;

function _rinfotext(rinfo:Prinfo;text:Pchar;len:integer;operation:integer):boolean;stdcall;
begin
   result:=eval_extra.RINFO_TEXT(rinfo,text,len,operation);
end;
function _estrSize(str:pchar):integer;stdcall;
begin
  result:=alloc.estrSize(str);
end;

function ConvertRinfoValueType(rinfo:Prinfo;rtype:integer;replacetype:boolean):boolean;
begin
  result:=eval.ConvertRinfoValueType(rinfo,rtype,replacetype);
end;

end.
