object E_form: TE_form
  Left = 197
  Top = 210
  BorderIcons = [biSystemMenu, biMaximize]
  BorderStyle = bsSingle
  Caption = 'Error'
  ClientHeight = 394
  ClientWidth = 601
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 601
    Height = 137
    Align = alTop
    BevelOuter = bvSpace
    TabOrder = 0
    OnResize = Panel1Resize
    object Label1: TLabel
      Left = 176
      Top = 104
      Width = 39
      Height = 13
      Caption = 'Label1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      Visible = False
    end
    object Button1: TButton
      Left = 518
      Top = 96
      Width = 75
      Height = 25
      Caption = 'Fermer'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object Button2: TButton
      Left = 96
      Top = 96
      Width = 75
      Height = 25
      Caption = 'Detail>>'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 8
      Top = 96
      Width = 75
      Height = 25
      Caption = 'Go to error'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Descript_text: TMemo
      Left = 8
      Top = 16
      Width = 585
      Height = 73
      Color = clBtnFace
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 137
    Width = 601
    Height = 257
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object detail: TRichEdit
      Left = 1
      Top = 1
      Width = 599
      Height = 233
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = []
      Lines.Strings = (
        'detail')
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
      OnChange = detailChange
      OnKeyPress = detailKeyPress
      OnMouseUp = detailMouseUp
    end
    object StatusBar1: TStatusBar
      Left = 1
      Top = 234
      Width = 599
      Height = 22
      Panels = <
        item
          Width = 50
        end>
    end
  end
end
