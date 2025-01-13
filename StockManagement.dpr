program StockManagement;

uses
  Vcl.Forms,
  MainView in 'MainView.pas' {Form1},
  UserModel in 'models\UserModel.pas',
  ItemModel in 'models\ItemModel.pas',
  AuthController in 'controllers\AuthController.pas',
  stockController in 'controllers\stockController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
