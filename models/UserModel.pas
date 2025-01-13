unit UserModel;

interface

uses
  FireDAC.Comp.Client;

type
  TUserModel = class
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    function ValidateLogin(const Username, Password: string): string; // Returns role
    procedure AddUser(const Username, Password, Role: string); // Adds a new user
  end;

implementation

constructor TUserModel.Create(AConnection: TFDConnection);
begin
  FConnection := AConnection;
end;

function TUserModel.ValidateLogin(const Username, Password: string): string;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT role FROM Users WHERE username = :username AND password = :password';
    Query.ParamByName('username').AsString := Username;
    Query.ParamByName('password').AsString := Password;
    Query.Open;
    if not Query.IsEmpty then
      Result := Query.FieldByName('role').AsString
    else
      Result := '';
  finally
    Query.Free;
  end;
end;

procedure TUserModel.AddUser(const Username, Password, Role: string);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'INSERT INTO Users (username, password, role) VALUES (:username, :password, :role)';
    Query.ParamByName('username').AsString := Username;
    Query.ParamByName('password').AsString := Password;
    Query.ParamByName('role').AsString := Role;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

end.
