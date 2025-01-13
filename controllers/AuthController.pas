unit AuthController;

interface

uses
  UserModel, System.JSON, FireDAC.Comp.Client, System.SysUtils;

type
  TAuthController = class
  private
    FUserModel: TUserModel;
  public
    constructor Create(AConnection: TFDConnection);
    function Login(const Username, Password: string): TJSONObject; // For login
    function Signup(const Username, Password, Role: string): TJSONObject; // For signup
  end;

implementation

constructor TAuthController.Create(AConnection: TFDConnection);
begin
  FUserModel := TUserModel.Create(AConnection);
end;

function TAuthController.Login(const Username, Password: string): TJSONObject;
var
  Role: string;
begin
  Result := TJSONObject.Create;
  Role := FUserModel.ValidateLogin(Username, Password);
  if Role <> '' then
  begin
    Result.AddPair('status', 'success');
    Result.AddPair('role', Role);
    Result.AddPair('username', Username);
  end
  else
  begin
    Result.AddPair('status', 'error');
    Result.AddPair('message', 'Invalid credentials');
  end;
end;

function TAuthController.Signup(const Username, Password, Role: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    // Add user to the database via UserModel
    FUserModel.AddUser(Username, Password, Role);
    Result.AddPair('status', 'success');
    Result.AddPair('message', 'User registered successfully');
  except
    on E: Exception do
    begin
      Result.AddPair('status', 'error');
      Result.AddPair('message', E.Message);
    end;
  end;
end;

end.
