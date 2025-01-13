unit StockController;

interface

uses
  System.SysUtils, FireDAC.Comp.Client, System.JSON;

type
  TStockController = class
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    function SellItem(const ItemName: string; const QuantityToSell: Integer): TJSONObject;
    function GetAllItems: TJSONArray;
    function AddItem(const ItemName: string; const Quantity: Integer): TJSONObject;
    function GetTotalItemsSold: TJSONObject;
    function GetLowStockAlerts: TJSONArray;
  end;

implementation

constructor TStockController.Create(AConnection: TFDConnection);
begin
  FConnection := AConnection;
end;

function TStockController.GetAllItems: TJSONArray;
var
  Query: TFDQuery;
  ItemObject: TJSONObject;
begin
  Result := TJSONArray.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT name, quantity FROM items';
    Query.Open;

    while not Query.Eof do
    begin
      ItemObject := TJSONObject.Create;
      ItemObject.AddPair('name', Query.FieldByName('name').AsString);
      ItemObject.AddPair('quantity', TJSONNumber.Create(Query.FieldByName('quantity').AsInteger));
      Result.AddElement(ItemObject);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TStockController.AddItem(const ItemName: string; const Quantity: Integer): TJSONObject;
var
  Query: TFDQuery;
begin
  Result := TJSONObject.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    // Check if the item already exists
    Query.SQL.Text := 'SELECT COUNT(*) AS Count FROM items WHERE name = :name';
    Query.ParamByName('name').AsString := ItemName;
    Query.Open;

    if Query.FieldByName('Count').AsInteger > 0 then
    begin
      Result.AddPair('status', 'error');
      Result.AddPair('message', 'Item already exists');
      Exit;
    end;

    // Insert the new item
    Query.SQL.Text := 'INSERT INTO items (name, quantity, total_quantity) VALUES (:name, :quantity, :quantity)';
    Query.ParamByName('name').AsString := ItemName;
    Query.ParamByName('quantity').AsInteger := Quantity;
    Query.ExecSQL;

    Result.AddPair('status', 'success');
    Result.AddPair('message', 'Item added successfully');
  finally
    Query.Free;
  end;
end;

function TStockController.SellItem(const ItemName: string; const QuantityToSell: Integer): TJSONObject;
var
  Query: TFDQuery;
  CurrentStock, NewStock, TotalStock: Integer;
  NotificationMessage: string;
begin
  Result := TJSONObject.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    // Check if the item exists and get current stock and total stock
    Query.SQL.Text := 'SELECT quantity, total_quantity FROM items WHERE name = :name';
    Query.ParamByName('name').AsString := ItemName;
    Query.Open;

    if Query.IsEmpty then
    begin
      Result.AddPair('status', 'error');
      Result.AddPair('message', 'Item not found');
      Exit;
    end;

    CurrentStock := Query.FieldByName('quantity').AsInteger;
    TotalStock := Query.FieldByName('total_quantity').AsInteger;

    // Check if there is enough stock
    if CurrentStock < QuantityToSell then
    begin
      Result.AddPair('status', 'error');
      Result.AddPair('message', 'Insufficient stock');
      Exit;
    end;

    // Calculate the new stock
    NewStock := CurrentStock - QuantityToSell;

    // Update the stock quantity in the database
    Query.SQL.Text := 'UPDATE items SET quantity = :quantity WHERE name = :name';
    Query.ParamByName('quantity').AsInteger := NewStock;
    Query.ParamByName('name').AsString := ItemName;
    Query.ExecSQL;

    // Check for notifications
    NotificationMessage := '';
    if NewStock <= (TotalStock div 4) then
      NotificationMessage := 'Quantity less than a quarter';
    if NewStock <= (TotalStock div 20) then
      NotificationMessage := 'Quantity nearing zero';

    // Return success with optional notification
    Result.AddPair('status', 'success');
    Result.AddPair('message', 'Item sold successfully');
    if NotificationMessage <> '' then
      Result.AddPair('notification', NotificationMessage);
  finally
    Query.Free;
  end;
end;

function TStockController.GetTotalItemsSold: TJSONObject;
var
  Query: TFDQuery;
  TotalSold: Integer;
begin
  Result := TJSONObject.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    Query.SQL.Text := 'SELECT SUM(total_quantity - quantity) AS total_sold FROM items';
    Query.Open;

    TotalSold := Query.FieldByName('total_sold').AsInteger;

    Result.AddPair('status', 'success');
    Result.AddPair('total_sold', TJSONNumber.Create(TotalSold));
  finally
    Query.Free;
  end;
end;


function TStockController.GetLowStockAlerts: TJSONArray;
var
  Query: TFDQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    Query.SQL.Text := 'SELECT name, quantity FROM items WHERE quantity <= (total_quantity * 0.25)';
    Query.Open;

    while not Query.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('name', Query.FieldByName('name').AsString);
      Item.AddPair('quantity', TJSONNumber.Create(Query.FieldByName('quantity').AsInteger));
      Result.AddElement(Item);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

end.
