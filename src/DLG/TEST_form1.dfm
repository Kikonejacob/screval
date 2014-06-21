object Form4: TForm4
  Left = 147
  Top = 108
  Width = 696
  Height = 480
  Caption = 'Form4'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 217
    Height = 201
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Lines.Strings = (
      '/*fggf*/Memo1;ab=5;'
      '{mp=65;dfd;=5}'
      'dffd;'
      '//mppdfdf'
      'ok=true;'
      'df=false;'
      'if(kjkjdf=0)'
      '{dfdffd=5}'
      'if(af=0) ffggfgf;')
    ParentFont = False
    TabOrder = 0
  end
  object Button1: TButton
    Left = 24
    Top = 344
    Width = 75
    Height = 25
    Caption = 'Scr_parser'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Memo2: TMemo
    Left = 232
    Top = 8
    Width = 449
    Height = 281
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object Button2: TButton
    Left = 8
    Top = 248
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 88
    Top = 248
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '5'
  end
  object Button3: TButton
    Left = 608
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Scr_eval'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 272
    Top = 304
    Width = 75
    Height = 25
    Caption = '//reg'
    TabOrder = 6
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 104
    Top = 320
    Width = 75
    Height = 25
    Caption = 'decomposeEX'
    TabOrder = 7
    OnClick = Button5Click
  end
  object myScreen: TMemo
    Left = 232
    Top = 336
    Width = 449
    Height = 105
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 8
  end
  object Button6: TButton
    Left = 368
    Top = 296
    Width = 121
    Height = 25
    Caption = 'EvalScriptFromFIle'
    TabOrder = 9
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 496
    Top = 296
    Width = 89
    Height = 25
    Caption = 'Virtual function'
    TabOrder = 10
    OnClick = Button7Click
  end
  object XPManifest1: TXPManifest
    Left = 136
    Top = 352
  end
end
