unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, uMonitorInfo;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var Info: TMonitorInfos;
    Len: Integer;
    i: Integer;
begin
  Info := nil;
  Memo1.Clear;
  if GetMonitorsInfo(Info, Len) then
    for i := 0 to Pred(Len) do
      begin
        Memo1.Lines.Add( Format('Monitor: #%d', [i]) );
        Memo1.Lines.Add( Format('Resolution: %d x %d px', [Info[i].ResolutionH, Info[i].ResolutionV]) );
        Memo1.Lines.Add( Format('Size: %f x %f cm', [Info[i].SizeH, Info[i].SizeV]) );
        Memo1.Lines.Add( Format('Diag: %f inch', [Info[i].Diagonal]) );
        Memo1.Lines.Add( Format('PPI: %f ', [Info[i].PPI]) );
        Memo1.Lines.Add( Format('Dot Pitch: %f mm', [Info[i].DotPitch]) );
        Memo1.Lines.Add( Format('Aspect Ratio: %s', [Info[i].AspectRatioStr]) );
        Memo1.Lines.Add( Format('Year: %d ', [Info[i].ManufactureYear]) );
        Memo1.Lines.Add( Format('Manufacturer: %s ', [Info[i].Manufacturer]) );
        Memo1.Lines.Add( Format('PNP: %s', [Info[i].PNPID]) );
        Memo1.Lines.Add('-----------');
      end;
end;

end.

