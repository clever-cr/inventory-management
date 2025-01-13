unit MainView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdCustomHTTPServer,
  IdHTTPServer, IdContext, System.JSON, IdBaseComponent, IdComponent,
  IdCustomTCPServer, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  UserModel, ItemModel, AuthController, StockController;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;

    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  private
    procedure LogMessage(const Msg: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Logging procedure for debugging
procedure TForm1.LogMessage(const Msg: string);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, 'server.log');
  if FileExists('server.log') then
    Append(LogFile)
  else
    Rewrite(LogFile);
  try
    Writeln(LogFile, DateTimeToStr(Now) + ': ' + Msg);
  finally
    CloseFile(LogFile);
  end;
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  AuthController: TAuthController;
  StockController: TStockController;
  JsonResponse: TJSONObject;
  JsonRequest: TJSONObject;
  JsonArray: TJSONArray;
  RequestBody: TStringStream;
begin
  AuthController := TAuthController.Create(FDConnection1);
  StockController := TStockController.Create(FDConnection1);
  try
    // Handle Login
    if (ARequestInfo.Command = 'POST') and (ARequestInfo.Document = '/api/login') then
    begin
      RequestBody := TStringStream.Create;
      try
        ARequestInfo.PostStream.Position := 0;
        RequestBody.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
        JsonRequest := TJSONObject.ParseJSONValue(RequestBody.DataString) as TJSONObject;
        try
          if Assigned(JsonRequest) then
          begin
            JsonResponse := AuthController.Login(
              JsonRequest.GetValue<string>('username'),
              JsonRequest.GetValue<string>('password')
            );

            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := JsonResponse.ToJSON;
            AResponseInfo.ResponseNo := 200; // HTTP 200 OK
          end
          else
          begin
            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := '{"status": "error", "message": "Invalid JSON"}';
            AResponseInfo.ResponseNo := 400; // HTTP 400 Bad Request
          end;
        finally
          JsonRequest.Free;
          JsonResponse.Free;
        end;
      finally
        RequestBody.Free;
      end;
    end

    // Handle Signup
    else if (ARequestInfo.Command = 'POST') and (ARequestInfo.Document = '/api/signup') then
    begin
      RequestBody := TStringStream.Create;
      try
        ARequestInfo.PostStream.Position := 0;
        RequestBody.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
        JsonRequest := TJSONObject.ParseJSONValue(RequestBody.DataString) as TJSONObject;
        try
          if Assigned(JsonRequest) then
          begin
            JsonResponse := AuthController.Signup(
              JsonRequest.GetValue<string>('username'),
              JsonRequest.GetValue<string>('password'),
              JsonRequest.GetValue<string>('role')
            );

            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := JsonResponse.ToJSON;
            AResponseInfo.ResponseNo := 201; // HTTP 201 Created
          end
          else
          begin
            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := '{"status": "error", "message": "Invalid JSON"}';
            AResponseInfo.ResponseNo := 400; // HTTP 400 Bad Request
          end;
        finally
          JsonRequest.Free;
          JsonResponse.Free;
        end;
      finally
        RequestBody.Free;
      end;
    end

    // Handle Add Item
    else if (ARequestInfo.Command = 'POST') and (ARequestInfo.Document = '/api/addItem') then
    begin
      RequestBody := TStringStream.Create;
      try
        ARequestInfo.PostStream.Position := 0;
        RequestBody.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
        JsonRequest := TJSONObject.ParseJSONValue(RequestBody.DataString) as TJSONObject;
        try
          if Assigned(JsonRequest) then
          begin
            JsonResponse := StockController.AddItem(
              JsonRequest.GetValue<string>('name'),
              JsonRequest.GetValue<Integer>('quantity')
            );

            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := JsonResponse.ToJSON;
            AResponseInfo.ResponseNo := 201; // HTTP 201 Created
          end
          else
          begin
            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := '{"status": "error", "message": "Invalid JSON"}';
            AResponseInfo.ResponseNo := 400; // HTTP 400 Bad Request
          end;
        finally
          JsonRequest.Free;
          JsonResponse.Free;
        end;
      finally
        RequestBody.Free;
      end;
    end

    // New API: Get Total Items Sold
    else if (ARequestInfo.Command = 'GET') and (ARequestInfo.Document = '/api/total-sold') then
    begin
      JsonResponse := StockController.GetTotalItemsSold;
      try
        AResponseInfo.ContentType := 'application/json';
        AResponseInfo.ContentText := JsonResponse.ToJSON;
        AResponseInfo.ResponseNo := 200; // HTTP 200 OK
      finally
        JsonResponse.Free;
      end;
    end

    // New API: Get Low Stock Alerts
    else if (ARequestInfo.Command = 'GET') and (ARequestInfo.Document = '/api/low-stock') then
    begin
      JsonArray := StockController.GetLowStockAlerts;
      try
        AResponseInfo.ContentType := 'application/json';
        AResponseInfo.ContentText := JsonArray.ToJSON;
        AResponseInfo.ResponseNo := 200; // HTTP 200 OK
      finally
        JsonArray.Free;
      end;
    end

     // Handle Get All Items
    else if (ARequestInfo.Command = 'GET') and (ARequestInfo.Document = '/api/items') then
    begin
      JsonArray := StockController.GetAllItems;
      try
        AResponseInfo.ContentType := 'application/json';
        AResponseInfo.ContentText := JsonArray.ToJSON;
        AResponseInfo.ResponseNo := 200; // HTTP 200 OK
      finally
        JsonArray.Free;
      end;
    end

     // Handle sell Items
    else if (ARequestInfo.Command = 'POST') and (ARequestInfo.Document = '/api/sellItem') then
    begin
      RequestBody := TStringStream.Create;
      try
        ARequestInfo.PostStream.Position := 0;
        RequestBody.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
        JsonRequest := TJSONObject.ParseJSONValue(RequestBody.DataString) as TJSONObject;
        try
          if Assigned(JsonRequest) then
          begin
            JsonResponse := StockController.SellItem(
              JsonRequest.GetValue<string>('name'),
              JsonRequest.GetValue<Integer>('quantity')
            );

            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := JsonResponse.ToJSON;
            AResponseInfo.ResponseNo := 200; // HTTP 200 OK
          end
          else
          begin
            AResponseInfo.ContentType := 'application/json';
            AResponseInfo.ContentText := '{"status": "error", "message": "Invalid JSON"}';
            AResponseInfo.ResponseNo := 400; // HTTP 400 Bad Request
          end;
        finally
          JsonRequest.Free;
          JsonResponse.Free;
        end;
      finally
        RequestBody.Free;
      end;
    end

    // Handle Unknown Routes
    else
    begin
      AResponseInfo.ContentType := 'application/json';
      AResponseInfo.ContentText := '{"status": "error", "message": "Endpoint not found"}';
      AResponseInfo.ResponseNo := 404; // HTTP 404 Not Found
    end;
  finally
    AuthController.Free;
    StockController.Free;
  end;
end;

end.
