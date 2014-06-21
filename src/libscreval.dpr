library libscreval;
{ Remarque importante concernant la gestion de m�moire de DLL : ShareMem doit
  �tre la premi�re unit� de la clause USES de votre biblioth�que ET de votre projet
  (s�lectionnez Projet-Voir source) si votre DLL exporte des proc�dures ou des
  fonctions qui passent des cha�nes en tant que param�tres ou r�sultats de fonction.
  Cela s'applique � toutes les cha�nes pass�es de et vers votre DLL --m�me celles
  qui sont imbriqu�es dans des enregistrements et classes. ShareMem est l'unit�
  d'interface pour le gestionnaire de m�moire partag�e BORLNDMM.DLL, qui doit
  �tre d�ploy� avec vos DLL. Pour �viter d'utiliser BORLNDMM.DLL, passez les
  informations de cha�nes avec des param�tres PChar ou ShortString. }

{%File 'eval.inc'}
{%File 'common.inc'}

{$I eval.inc}

uses
  SysUtils,
  Classes,
  errCode in 'errCode.pas',
  eval in 'eval.pas',
  gutils in '..\gutils.pas',
  eval_extra in 'eval_extra.pas',
  regeval in 'regeval.pas',
  scr_reg_eval in 'scr_reg_eval.pas',
  script in 'script.pas',
  main in 'main.pas',
  common in 'common.pas',
  DLG_SCR_ERROR in 'DLG\DLG_SCR_ERROR.pas' {E_form},
  EP_errdlg in 'DLG\EP_errdlg.pas' {ErrForm},
  alloc in 'alloc.pas';

{$R *.res}

exports

         main.EvalScriptFromFile,
         main.scriptEvalEx,
         main.ScriptFileEval,
         main.GetFunc,
         main.SetFunc,
         main.Setvar,
         main.Getvar,
         main.fill_scr,
         main.initEval,
         main.fillrinfo,
         main.SetEvalHook,
         main.CreateEvalProcess,
         main.CreateEvalProcessEx,
         main.ExpEvalEx,
         main.ExpEval,
         main.AddReadyNamespace,
         //main.AddNamespace,
         main.deleteVar,
         main.deleteVars,
         main.deleteFuncs,
         main.deleteNamespace,
         main.addScrDependency,
         main.GetConst,
         main.rtypeToStrEx,
         main.rtypeToStr,
         main.cnv_rinfoTostr,
         main.isnumeric,
         main.run_scr,
         {main.array_create,
         main.array_setvalue,
         main.array_deletevalue,
         main.array_delete, }
         main.UnsetEvalHook,
         main.DeleteEvalProcess,
         main.GetNamespaces,
         main.GetFuncs,
         main.Getvars,
         {array}
         main.array_create,
         main.array_delete,
         main.array_get,
         main.array_getvalue,
         main.array_setvalue,
         main.array_deletevalue,
         main.class_add,
         main.class_addmethode,
         main.class_addproperty,
         main.class_delete,
         main.class_deletemethode,
         main.class_deleteproperty,

         main._enew,
         main._edispose,
         main._estrAlloc,
         main._estrDispose,
         main._estring,

         main._newrinfo,
         main._newfunc,
         main._newepinfo,
         main._freerinfo,
         main._freefunc,
         main._freeepinfo,
         main._fillfunc,
         main._fillepinfo,

         main.getrInfoStr,
         main.getfuncParam,
         main.enew2,
         main._rinfotext,
         main._estrSize,
         main.vfunc_getvarAddress,
         main._newEvalEventHook,
         main.ConvertRinfoValueType;




begin

end.
