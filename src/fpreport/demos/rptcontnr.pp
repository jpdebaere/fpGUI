unit rptcontnr;


{$mode objfpc}{$H+}
{$I demos.inc}

interface

uses
  Classes,
  SysUtils,
  fpreport,
  fpreportcontnr,
  contnrs,
  udapp;

type

  { TCountry }

  TCountry = Class(TCollectionItem)
  private
    FName: String;
    FPopulation: Int64;
  Published
    Property Name : String Read FName Write FName;
    Property Population : Int64 Read FPopulation Write FPopulation;
  end;

  { TCollectionDemo }

  TContnrDemo = class(TReportDemoApp)
  Protected
    FReportData : TFPReportObjectData;
  public
    procedure   CreateReportDesign;override;
    procedure   LoadDesignFromFile(const AFilename: string);
    procedure   HookupData(const AComponentName: string; const AData: TFPReportData);
    destructor  Destroy; override;
  end;

  TCollectionDemo = class(TContnrDemo)
  Protected
    procedure   InitialiseData; override;
  Public
    constructor Create(AOWner :TComponent); override;
    Class function Description : string; override;
  end;

  { TObjectListDemo }

  TObjectListDemo = class(TContnrDemo)
  Protected
    procedure   InitialiseData; override;
  Public
    constructor Create(AOWner :TComponent); override;
    Class function Description : string; override;
  end;


implementation

uses
  fpReportStreamer,
  fpTTF,
  fpJSON,
  jsonparser;

{ TObjectListDemo }

procedure TObjectListDemo.InitialiseData;
Var
  SL : TStringList;
  i : Integer;
  N,V : String;
  C : TCountry;
  List : TFPObjectList;

begin
  List:=TFPObjectList.Create(True);
  TFPReportObjectListData(FReportData).List:=List;
  SL:=TStringList.Create;
  try
    {$I countries.inc}
    SL.Sort;
    For I:=0 to SL.Count-1 do
      begin
      C:=TCountry.Create(Nil);
      List.Add(C);
      SL.GetNameValue(I,N,V);
      C.Name:=N;
      C.Population:=StrToInt64Def(V,0);
      end;
  finally
    SL.Free;
  end;
end;

constructor TObjectListDemo.Create(AOWner: TComponent);
begin
  inherited Create(AOWner);
  FReportData := TFPReportObjectListData.Create(nil);
  TFPReportObjectListData(FReportData).OwnsList:=True;
end;

class function TObjectListDemo.Description: string;
begin
  Result:='Demo to show support for object Lists as data loop';
end;


procedure TContnrDemo.CreateReportDesign;
var
  p: TFPReportPage;
  TitleBand: TFPReportTitleBand;
  DataBand: TFPReportDataBand;
  GroupHeader: TFPReportGroupHeaderBand;
  Memo: TFPReportMemo;
  PageFooter: TFPReportPageFooterBand;

begin
  inherited CreateReportDesign;
  rpt.Author := 'Graeme Geldenhuys';
  rpt.Title := 'FPReport Demo 12 - JSON Data';

  p :=  TFPReportPage.Create(rpt);
  p.Orientation := poPortrait;
  p.PageSize.PaperName := 'A4';
  { page margins }
  p.Margins.Left := 30;
  p.Margins.Top := 20;
  p.Margins.Right := 30;
  p.Margins.Bottom := 20;
  p.Data := FReportData;
  p.Font.Name := 'LiberationSans';

  TitleBand := TFPReportTitleBand.Create(p);
  TitleBand.Layout.Height := 40;
  {$ifdef ColorBands}
  TitleBand.Frame.Shape := fsRectangle;
  TitleBand.Frame.BackgroundColor := clReportTitleSummary;
  {$endif}

  Memo := TFPReportMemo.Create(TitleBand);
  Memo.Layout.Left := 35;
  Memo.Layout.Top := 20;
  Memo.Layout.Width := 80;
  Memo.Layout.Height := 10;
  Memo.Text := 'COUNTRY AND POPULATION AS OF 2014';

  GroupHeader := TFPReportGroupHeaderBand.Create(p);
  GroupHeader.Layout.Height := 15;
  GroupHeader.GroupCondition := 'copy(''[Name]'',1,1)';
  {$ifdef ColorBands}
  GroupHeader.Frame.Shape := fsRectangle;
  GroupHeader.Frame.BackgroundColor := clGroupHeaderFooter;
  {$endif}

  Memo := TFPReportMemo.Create(GroupHeader);
  Memo.Layout.Left := 0;
  Memo.Layout.Top := 5;
  Memo.Layout.Width := 10;
  Memo.Layout.Height := 8;
  Memo.UseParentFont := False;
  Memo.Text := '[copy(Name,1,1)]';
  Memo.Font.Size := 16;

  DataBand := TFPReportDataBand.Create(p);
  DataBand.Layout.Height := 8;
  {$ifdef ColorBands}
  DataBand.Frame.Shape := fsRectangle;
  DataBand.Frame.BackgroundColor := clDataBand;
  {$endif}

  Memo := TFPReportMemo.Create(DataBand);
  Memo.Layout.Left := 15;
  Memo.Layout.Top := 0;
  Memo.Layout.Width := 50;
  Memo.Layout.Height := 5;
  Memo.Text := '[Name]';

  Memo := TFPReportMemo.Create(DataBand);
  Memo.Layout.Left := 70;
  Memo.Layout.Top := 0;
  Memo.Layout.Width := 30;
  Memo.Layout.Height := 5;
  Memo.Text := '[formatfloat(''#,##0'', Population)]';


  PageFooter := TFPReportPageFooterBand.Create(p);
  PageFooter.Layout.Height := 20;
  {$ifdef ColorBands}
  PageFooter.Frame.Shape := fsRectangle;
  PageFooter.Frame.BackgroundColor := clPageHeaderFooter;
  {$endif}

  Memo := TFPReportMemo.Create(PageFooter);
  Memo.Layout.Left := 130;
  Memo.Layout.Top := 13;
  Memo.Layout.Width := 20;
  Memo.Layout.Height := 5;
  Memo.Text := 'Page [PageNo]';
  Memo.TextAlignment.Vertical := tlCenter;
  Memo.TextAlignment.Horizontal := taRightJustified;
end;

procedure TContnrDemo.LoadDesignFromFile(const AFilename: string);
var
  rs: TFPReportJSONStreamer;
  fs: TFileStream;
  lJSON: TJSONObject;
begin
  if AFilename = '' then
    Exit;
  if not FileExists(AFilename) then
    raise Exception.CreateFmt('The file "%s" can not be found', [AFilename]);
  fs := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    lJSON := TJSONObject(GetJSON(fs));
  finally
    fs.Free;
  end;
  rs := TFPReportJSONStreamer.Create(nil);
  rs.JSON := lJSON; // rs takes ownership of lJSON
  try
    rpt.ReadElement(rs);
  finally
    rs.Free;
  end;
end;

procedure TContnrDemo.HookupData(const AComponentName: string; const AData: TFPReportData);
var
  b: TFPReportCustomBandWithData;
begin
  b := TFPReportCustomBandWithData(rpt.FindRecursive(AComponentName));
  if Assigned(b) then
    b.Data := AData;
end;

destructor TContnrDemo.Destroy;
begin
  FreeAndNil(FReportData);
  inherited Destroy;
end;

constructor TCollectionDemo.Create(AOWner: TComponent);
begin
  inherited;
  FReportData := TFPReportCollectionData.Create(nil);
  TFPReportCollectionData(FReportData).OwnsCollection:=True;
end;

class function TCollectionDemo.Description: string;
begin
  Result:='Demo showing native support for collections as data loop';
end;

{ TCollectionDemo }

procedure TCollectionDemo.InitialiseData;

Var
  SL : TStringList;
  i : Integer;
  N,V : String;
  C : TCountry;
  Coll : TCollection;

begin
  Coll:=TCollection.Create(TCountry);
  TFPReportCollectionData(FReportData).Collection:=coll;
  SL:=TStringList.Create;
  try
    {$I countries.inc}
    SL.Sort;
    For I:=0 to SL.Count-1 do
      begin
      C:=Coll.Add As TCountry;
      SL.GetNameValue(I,N,V);
      C.Name:=N;
      C.Population:=StrToInt64Def(V,0);
      end;
  finally
    SL.Free;
  end;
end;

end.

