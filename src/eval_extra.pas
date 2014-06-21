unit eval_extra;

interface
uses eval,sysUtils,alloc,dialogs;



procedure rinfoCopy(dest,source:Prinfo);
procedure EpInfoCopy(dest,source:PepInfo);
procedure funcCopy(dest,source:Pfunc);

function E_STRING(str:string):pchar;  overload;
function E_STRING(str:Pchar):pchar;  overload;

function newrinfo:Prinfo;
function newfunc:Pfunc;
function newEpInfo:PEpInfo;
function newEvalEventHook:PEvalEventHook;
function GetFuncParam(PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;



procedure FillEpInfo(epInfo:PepInfo);
procedure FillFunc(func:Pfunc);


procedure freefunc(func:Pfunc);
procedure freeEpInfo(epInfo:PepInfo);
procedure freerinfo(rinfo:prinfo);

function   RINFO_TEXT(rinfo:Prinfo;text:Pchar;bufSize:integer;operation:integer):boolean;
procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar;const len:integer);overload;
procedure  RINFO_CATTEXT(rinfo:Prinfo;text:Pchar;const len:integer);

function ns_getfunctionstr(PID:integer;namespace:string;includeHeritage:boolean):string;
function ns_getvariablesString(PID:integer;namespace:string;includeHeritage:boolean):string;


procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar);overload;



implementation


function GetFuncParam(PID:integer;name:pchar;epInfo:pointer):Prinfo; stdcall;
begin
  result:=eval.GetvarAdress(PID,name,Pepinfo(epInfo).group)
end;

procedure EpInfoCopy(dest,source:PepInfo);
begin
  //dest^:=source^;

  if assigned(dest.ErrNamespace) then StrDispose(dest.ErrNamespace);
  if assigned(dest.ErrParams)    then StrDispose(dest.ErrParams);
  if assigned(dest.group)        then strDispose(dest.group);

  dest.ForUser:=source.ForUser;
  dest.cmd:=source.cmd;
  dest.cArg1:=source.cArg1;
  dest.cArg2:=source.cArg2;
  dest.cArg3:=source.cArg3;
  dest.traited:=source.traited;
  dest.x:=source.x;
  dest.y:=source.y;
  dest.ListRootStr:=source.ListRootStr;
  dest.KeyValue:=source.KeyValue;
  dest.ErrId:=source.ErrId;
  if assigned(source.ErrParams) then dest.ErrParams:=E_STRING(source.ErrParams);
  dest.ErrPos:=source.ErrPos;
  if assigned(source.ErrNamespace) then dest.ErrNamespace:=E_STRING(source.ErrNamespace);
  dest.ErrLn:=source.ErrLn;
  dest.ErrRigthLnCount:=source.ErrRigthLnCount;
  dest.ErrStrPos:=source.ErrStrPos;
  dest.ErrDeclationMode:=source.ErrDeclationMode;
  dest.BreakChar:=source.BreakChar;
  dest.scr:=source.scr;
  if assigned(source.group) then dest.group:=E_STRING(source.group);
  dest.prev_traited:=source.prev_traited;
  dest.silentMode:=source.silentMode;
  dest.groupIndex:=source.groupIndex;
  dest.groupParentIndex:=source.groupParentIndex;
  dest.defaultMemberAccess:=source.defaultMemberAccess;
  dest.PID:=source.PID;
  dest.IncorporetedScript:=Source.IncorporetedScript;


end;

procedure rinfoCopy(dest,source:Prinfo);
begin
  if assigned(dest.group)            then strDispose(dest.group);
  if assigned(dest.heritedNameSpace) then strDispose(dest.heritedNameSpace);
  if assigned(dest.reference)        then strDispose(dest.reference);
  if assigned(dest.DefaultValue)     then strDispose(dest.DefaultValue);
  dest.IntValue:=source.IntValue;
  //if assigned(source.CharValue) then strLcopy(dest.CharValue,source.CharValue,dest.CharBuffSize);
  if assigned(source.CharValue) then
  begin
    if assigned(dest.CharValue) then
    begin
      if (StrBufSize(source.CharValue)>StrBufSize(dest.CharValue)) then
      begin
        strDispose(dest.CharValue);
        dest.CharValue:=strAlloc(StrBufSize(source.CharValue));
      end
    end
    else
      dest.CharValue:=stralloc(strBufSize(source.CharValue));
    strLcopy(dest.CharValue,source.CharValue,strBufSize(dest.Charvalue));
  end;
  //dest.CharBuffSize:=source.CharBuffSize;
  dest.BoolValue:=source.BoolValue;
  dest.rtype:=source.rtype;
  dest.rtypestr:=source.rtypestr;
  dest.ErrId:=source.ErrId;
  dest.floatvalue:=source.floatvalue;
  dest.pt:=source.pt;
  dest.name:=source.name;
  if assigned(source.group) then dest.group:=E_STRING(source.group);
  //showmessage(source.group);
  dest.arrays:=source.arrays;
  dest.access:=source.access;
  if assigned(source.heritedNameSpace) then dest.heritedNameSpace:=E_STRING(source.heritedNameSpace);
  dest.isReference:=source.isReference;
  if assigned(source.reference) then dest.reference:=E_STRING(source.reference);
  if assigned(source.DefaultValue) then dest.DefaultValue:=E_STRING(source.DefaultValue);
  dest.key:=source.key;
  dest.PID:=source.PID;  //attention

end;

function E_STRING(str:string):pchar;
begin
  result:=estring(Pchar(str),length(str));
end;

function E_STRING(str:Pchar):pchar;
begin
  result:=estring(str,strlen(str));
end;


function RINFO_TEXT(rinfo:Prinfo;text:Pchar;bufSize:integer;operation:integer):boolean;
begin

  if assigned(text) then
  begin
    if assigned(rinfo.CharValue) then
    begin
      if (bufSize>StrBufSize(rinfo.CharValue)) then
      begin
        strDispose(rinfo.CharValue);
        rinfo.CharValue:=strAlloc(BufSize);
      end
    end
    else
      rinfo.CharValue:=stralloc(BufSize);
    strLcopy(rinfo.CharValue,text,strBufSize(rinfo.Charvalue));
  end;
end;

procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar;const len:integer);
begin
  RINFO_TEXT(rinfo,text,StrLen(text)+1,TextOperation_Copy);
end;

procedure  RINFO_COPYTEXT(rinfo:Prinfo;text:Pchar);
begin
  RINFO_TEXT(rinfo,text,StrLen(text)+1,TextOperation_copy);
end;



procedure  RINFO_CATTEXT(rinfo:Prinfo;text:Pchar;const len:integer);
begin
  RINFO_TEXT(rinfo,text,StrLen(text)+1,TextOperation_cat);
end;


procedure freefunc(func:Pfunc);
begin
  //StrDispose(rinfo.charvalue);
  //if func.params<>nil then strDispose(func.params);
  //if func.groupe<>nil then strDispose(func.groupe);
  //if func.heritedNameSpace<>nil then strDispose(func.groupe);
  if assigned(func.params)           then strDispose(func.params);
  if assigned(func.groupe)           then strDispose(func.groupe);
  if assigned(func.heritedNameSpace) then strDispose(func.heritedNameSpace);
  dispose(func);
  //freemem(func);
end;

procedure funcCopy(dest,source:Pfunc);
begin
   //showmessage(source.name);
   if assigned(dest.params)           then strDispose(dest.params);
   if assigned(dest.groupe)           then strDispose(dest.groupe);
   if assigned(dest.heritedNameSpace) then strDispose(dest.heritedNameSpace);
   dest.ftype:=source.ftype;
   dest.name:=source.name;
   
   if assigned(source.params) then dest.params:=E_STRING(source.params);
   dest.pfunc:=source.pfunc;
   dest.helpfunc:=source.helpfunc;
   dest.lib:=source.lib;
   dest.rtype:=source.rtype;
   if assigned(source.groupe) then dest.groupe:=E_STRING(source.groupe);
   dest.PID:=source.PID;
   dest.v_instruct:=source.v_instruct;
   dest.v_location:=source.v_location;
   if assigned(source.heritedNameSpace) then dest.heritedNameSpace:=E_STRING(source.heritedNameSpace);
   dest.access:=source.access;
end;

function newfunc:Pfunc;
var
  P:Pfunc;
begin
  //new(P);
  //getMem(P,sizeof(dfunc));
  P:=allocMem(sizeof(dfunc));
  P.params:=nil;
  P.groupe:=nil;
  P.heritedNameSpace:=nil;
  result:=P;
end;

function newEvalEventHook:PEvalEventHook;
var
  P:PEvalEventHook;
begin
  //new(P);
  //getMem(P,sizeof(dfunc));
  P:=allocMem(sizeof(dEvalEventHook));
  P.cbsize:=sizeof(P);
  result:=P;
end;

function newEpInfo:PEpInfo;
var
  epInfo:PepInfo;
begin
  //new(epInfo);
  epInfo:=allocMem(sizeof(dEpInfo));
  epInfo.ErrParams:=nil;
  epInfo.ErrNamespace:=nil;
  epInfo.group:=nil;
  epInfo.cArg3:=nil;
  epInfo.scr:=nil;
  result:=epInfo;
end;
function newrinfo:Prinfo;
var
  p:Prinfo;
begin
  //new(p);
  P:=allocMem(sizeof(drinfo));
  p.CharValue:=nil;
  P.group:=nil;
  P.heritedNameSpace:=nil;
  P.reference:=nil;
  P.DefaultValue:=nil;
  result:=p;
end;

procedure FillEpInfo(epInfo:PepInfo);
begin
  epInfo.ErrParams:=nil;
  epInfo.ErrNamespace:=nil;
  epInfo.group:=nil;
  epInfo.BreakChar:='';
  epInfo.ListRootStr:='';
  epInfo.cArg1:='';
  epInfo.cArg3:=nil;
  epInfo.scr:=nil;
  epInfo.prev_traited:=pt_none;
end;

procedure FillFunc(func:Pfunc);
begin
  func.params:=nil;
  func.name:='';
  func.lib:='';
  func.groupe:=nil;
  func.pfunc:=nil;
  func.helpfunc:=nil;
  func.v_instruct:=nil;
  func.heritedNameSpace:=nil;
end;

procedure freeEpInfo(epInfo:PepInfo);
begin
   if assigned(epInfo.ErrParams) then strDispose(epInfo.ErrParams);
   if assigned(epInfo.ErrNamespace) then strDispose(epInfo.ErrNamespace);
   if assigned(epInfo.group) then strDispose(epInfo.group);
   //dispose(epInfo);
   freemem(epInfo);
end;

procedure freerinfo(rinfo:prinfo);
begin
 // showmessage(rinfo.name);
  if assigned(rinfo.CharValue)        then StrDispose(rinfo.charvalue);
  if assigned(rinfo.group)            then strDispose(rinfo.group);
  if assigned(rinfo.heritedNameSpace) then strDispose(rinfo.heritedNameSpace);
  if assigned(rinfo.reference)        then strDispose(rinfo.reference);
  if assigned(rinfo.DefaultValue)     then strDispose(rinfo.DefaultValue);
  dispose(rinfo);
  //freemem(rinfo);
end;


 {fonction qui permet d'avoir la liste des variables d'un namespace}
function ns_getvariablesString(PID:integer;namespace:string;includeHeritage:boolean):string;
var
  i,nsid:integer;
  varinfo:Pvarinfo;
begin
  varinfo:=nil;
  nsid:=indexFromNameSpace(namespace,PID);
  for i:=0 to varlist.count-1 do
  if (Pvarinfo(varlist[i]).group=namespace) and (CanAccessProc(Pvarinfo(varlist[i]).PID,PID)) then
  begin
    result:=result+Pvarinfo(varlist[i]).name+';';
  end;
  if (includeHeritage) and (pscrInfo(namespacelist[nsid]).heritedNameSpace<>'') then
  ns_getvariablesString(PID,pscrInfo(namespacelist[nsid]).heritedNameSpace,IncludeHeritage);
end;



{fonction qui permet d'avoir la liste de toutes les fonctions d'un namespace}
function ns_getfunctionstr(PID:integer;namespace:string;includeHeritage:boolean):string;
var
  i,nsid:integer;
  func:Pfunc;
begin
  nsid:=indexFromNameSpace(namespace,PID);
  for i:=0 to funclist.count-1 do
  if (Pfunc(funclist[i]).groupe=namespace) and (CanAccessProc(Pfunc(funclist[i]).PID,PID)) then
  begin
     result:=result+Pfunc(funclist[i]).name+';';
  end;
  if (includeHeritage) and (pscrInfo(namespacelist[nsid]).heritedNameSpace<>'') then
  ns_getfunctionStr(PID,pscrInfo(namespacelist[nsid]).heritedNameSpace,IncludeHeritage);


end;


end.
