unit alloc;
{3 aout 2011}

interface
uses sysUtils;


procedure estrDispose(str:pchar);
function estrAlloc(size:integer):pchar;
procedure edispose(ptr:Pointer);
function enew(size:integer):pointer;
function estring(str:pchar;len:integer):pchar;
function estrSize(str:Pchar):integer;



implementation


function enew(size:integer):pointer;
begin
   result:=allocMem(size);
   //getMem(result,size);
  // Initialize(result);
end;
procedure edispose(ptr:Pointer);
begin
//  finalize(ptr^);
  FreeMem(ptr);
 // dispose(ptr);
end;

function estrAlloc(size:integer):pchar;
begin
  result:=StrAlloc(size);
end;

function estring(str:pchar;len:integer):pchar;
var
 p:pchar;
begin
 if str=nil then
 begin
   result:=nil;exit;
 end;
 p:=estralloc(len+1);
 strLcopy(p,str,len);
 result:=p;
end;

procedure estrDispose(str:pchar);
begin
  strDispose(str);
end;


function estrSize(str:pchar):integer;
begin
  result:=strbufSize(str);
end;




end.
 