object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object IdHTTPServer1: TIdHTTPServer
    Active = True
    Bindings = <>
    DefaultPort = 8080
    AutoStartSession = True
    OnCommandGet = IdHTTPServer1CommandGet
    Left = 48
    Top = 80
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      
        'Database=C:\Users\fabrice\Documents\Embarcadero\Studio\Projects\' +
        'Inventory-management\inventory_db.db'
      'DriverID=SQLite')
    Left = 288
    Top = 64
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    Left = 224
    Top = 160
  end
end
