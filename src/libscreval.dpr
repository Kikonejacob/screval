library libscreval;
{ Remarque importante concernant la gestion de mémoire de DLL : ShareMem doit
  être la première unité de la clause USES de votre bibliothèque ET de votre projet
  (sélectionnez Projet-Voir source) si votre DLL exporte des procédures ou des
  fonctions qui passent des chaînes en tant que paramètres ou résultats de fonction.
  Cela s'applique à toutes les chaînes passées de et vers votre DLL --même celles
  qui sont imbriquées dans des enregistrements et classes. ShareMem est l'unité
  d'interface pour le gestionnaire de mémoire partagée BORLNDMM.DLL, qui doit
  être déployé avec vos DLL. Pour éviter d'utiliser BORLNDMM.DLL, passez les
  informations de chaînes avec des paramètres PChar ou ShortString. }

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
