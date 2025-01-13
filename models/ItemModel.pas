unit ItemModel;

interface

uses
  FireDAC.Comp.Client, System.SysUtils, System.JSON;

type
  TItemModel = class
  private
    FConnection: TFDConnection; // Declare the connection field
  public
    constructor Create(AConnection: TFDConnection);
    procedure AddItem(const Name: string; Quantity: Integer);
    function SellItem(const Name: string; Quantity: Integer): TJSONObject; // Matches the declaration
    function GetAllItems: TJSONArray; // Fetches all items from the database
  end;

implementation

constructor TItemModel.Create(AConnection: TFDConnection);
begin
  FConnection := AConnection; // Assign the database connection
end;

procedure TItemModel.AddItem(const Name: string; Quantity: Integer);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'INSERT INTO Items (name, quantity) VALUES (:name, :quantity)';
    Query.ParamByName('name').AsString := Name;
    Query.ParamByName('quantity').AsInteger := Quantity;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TItemModel.SellItem(const Name: string; Quantity: Integer): TJSONObject;
var
  Query: TFDQuery;
  CurrentQuantity: Integer;
  ResultJson: TJSONObject;
begin
  ResultJson := TJSONObject.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    // Check current stock quantity
    Query.SQL.Text := 'SELECT quantity FROM Items WHERE name = :name';
    Query.ParamByName('name').AsString := Name;
    Query.Open;

    if Query.IsEmpty then
    begin
      ResultJson.AddPair('status', 'error');
      ResultJson.AddPair('message', 'Item not found');
      Exit(ResultJson);
    end;

    CurrentQuantity := Query.FieldByName('quantity').AsInteger;
    if CurrentQuantity < Quantity then
    begin
      ResultJson.AddPair('status', 'error');
      ResultJson.AddPair('message', 'Insufficient stock to complete the sale');
      Exit(ResultJson);
    end;

    // Reduce the stock quantity
    Query.SQL.Text := 'UPDATE Items SET quantity = quantity - :quantity WHERE name = :name';
    Query.ParamByName('quantity').AsInteger := Quantity;
    Query.ExecSQL;

    // Success response
    ResultJson.AddPair('status', 'success');
    ResultJson.AddPair('message', 'Item sold successfully');
    Exit(ResultJson);
  finally
    Query.Free;
  end;
end;

function TItemModel.GetAllItems: TJSONArray;
var
  Query: TFDQuery;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
begin
  JsonArray := TJSONArray.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT id, name, quantity FROM Items';
    Query.Open;

    while not Query.Eof do
    begin
      JsonObject := TJSONObject.Create;
      JsonObject.AddPair('id', TJSONNumber.Create(Query.FieldByName('id').AsInteger));
      JsonObject.AddPair('name', Query.FieldByName('name').AsString);
      JsonObject.AddPair('quantity', TJSONNumber.Create(Query.FieldByName('quantity').AsInteger));
      JsonArray.AddElement(JsonObject);

      Query.Next;
    end;

    Result := JsonArray;
  finally
    Query.Free;
  end;
end;

end.
