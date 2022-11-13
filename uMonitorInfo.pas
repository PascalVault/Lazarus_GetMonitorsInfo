unit uMonitorInfo;

interface

//Version: 0.6 (2022-11-13)
//Author: domasz
//Updates: howardpc, KodeZwerg
//Licence: MIT

uses
  SysUtils, Variants, Classes, Registry, ComObj, Windows, Math;

type
  TCompany = record
    Short: String;
    Full: String;
  end;

const Company: array[0..2673] of TCompany = (
  {$INCLUDE Company.inc}
);

type

  TMonitorInfo = record
    ResolutionV: Integer;
    ResolutionH: Integer;
    SizeV: Extended;
    SizeH: Extended;
    SizeVInch: Extended;
    SizeHInch: Extended;
    PPI: Extended;
    Diagonal: Extended;
    ManufactureYear: Integer;
    Manufacturer: String;
    DotPitch: Extended;
    AspectRatio: Extended;
    AspectRatioV: Int64;
    AspectRatioH: Int64;
    AspectRatioStr: String;
    PNPID: String;
  end;

  TMonitorInfos = array of TMonitorInfo;

  _DISPLAY_DEVICEA_EX = packed record
     cb: DWORD;
     DeviceName: array[0..31] of AnsiChar;
     DeviceString: array[0..127] of AnsiChar;
     StateFlags: DWORD;
     DeviceID: array[0..127] of AnsiChar;
     DeviceKey: array[0..127] of AnsiChar;
  end;
  TDisplayDeviceAEx = _DISPLAY_DEVICEA_EX;

  function GetMonitorsInfo(var Info: TMonitorInfos; out Count: Integer): Boolean;

  function EnumDisplayDevicesAEx(Unused: Pointer; iDevNum: DWORD;
     var lpDisplayDevice: TDisplayDeviceAEx; dwFlags: DWORD): BOOL; stdcall; external user32 name 'EnumDisplayDevicesA';

implementation

function BinFind(Short: String; Count: Integer): Integer;
var L,R,M: Integer;
begin
  L := 0;
  R := Count - 1;

  while L <> R do begin
    M := ceil((L + R) / 2);
    if Company[M].Short > Short then R := M - 1
    else                             L := M;
  end;

  if Company[L].Short = Short then Result := L
  else                             Result := -1;
end;

function GetMonitorIds: TStringList;
 var Devices, Monitor: _DISPLAY_DEVICEA_EX;
     i,j: Integer;
     Split: TStringList;
begin
  Result := TStringList.Create;
  Split := TStringList.Create;
  try
    Split.Delimiter := '\';

    FillChar(Devices{%H-}, SizeOf(Devices), 0);
    Devices.cb := SizeOf(Devices);

    FillChar(Monitor{%H-}, SizeOf(Monitor), 0);
    Monitor.cb := SizeOf(Monitor);

    i := 0;
    while EnumDisplayDevicesAEx(nil, i, Devices, 0) do begin
      j := 0;
      while EnumDisplayDevicesAEx(@Devices.DeviceName[0], j, Monitor, 0) do begin

        Split.DelimitedText := Monitor.Deviceid;
        Result.Add(Split[1]);

        Inc(j);
      end;
      Inc(i);
    end;
  finally
    Split.Free;
  end;
end;

function DecodeManufacturer(Val: Word): String;
var A,B,C: Byte;
    Short: String;
    i: Integer;
begin
  A := (Val shr 10) and 31;
  B := (Val shr  5) and 31;
  C := (Val       ) and 31;

  Inc(A,64);
  Inc(B,64);
  Inc(C,64);

  Short := Chr(A)+Chr(B)+Chr(C);
  Result := Short;

  i := BinFind(Short, High(Company)+1);
  if i>-1 then Result := Company[i].Full;
end;

function GGT(NumberA, NumberB: Int64): Int64;
  function Even(const Input: Int64): Boolean;
  begin
    Result := not Odd(Input);
  end;
var
  K, T : Int64;
begin
  if (NumberA = 0) then begin
    Result := NumberB;
    Exit;
  end;

  K := 0;
  while (Even(NumberA) and Even(NumberB)) do
    begin
      NumberA := NumberA div 2;
      NumberB := NumberB div 2;
      Inc(K);
    end;
  if (Odd(NumberA)) then
    T := -NumberB
  else
    T := NumberA;
  while (T <> 0) do
    begin
      while (Even(T)) do
        T := T div 2;
        if (T > 0) then
          NumberA := T
        else
          NumberB := -T;
        T := NumberA - NumberB;
      end;
  if (K = 0) then
    Result := NumberA
  else
    Result := NumberA * (2 shl (K - 1));
end;

function GetMonitorsInfo(var Info: TMonitorInfos; out Count: Integer): Boolean;
const
  dtd = 54;
var
  Reg: TRegistry;
  Res: Boolean;
  Size, k: Integer;
  EDID: array of Byte;
  Diag: Extended;
  RegKey: String;
  Monitors, Keys: TStringList;
  AspDiv: Int64;
begin
  Result := False;
  Monitors := GetMonitorIds;
  if Monitors.Count = 0 then begin
    Monitors.Free;
    Exit;
  end;
  try
    SetLength(Info, Monitors.Count);
    Count := Monitors.Count;
    Keys := TStringList.Create;
    try
      for k := 0 to Pred(Count) do
        begin
          RegKey := 'SYSTEM\CurrentControlSet\Enum\DISPLAY\' + Monitors[k];
          FillChar(Result, SizeOf(Result), 0);
          Info[k].PNPID := Monitors[k];
          Reg := TRegistry.Create(KEY_READ);
          try
            Reg.RootKey := HKEY_LOCAL_MACHINE;
            Res := Reg.OpenKey(RegKey, false);
            Reg.GetKeyNames(Keys);
            if (Keys.Count > 0) then
              begin
                Reg.CloseKey;
                Res := Reg.OpenKey(RegKey + '\' + Keys[0] + '\Device Parameters', false);
                if Res then
                  begin
                    Size := Reg.GetDataSize('EDID');
                    EDID := nil;
                    if (Size > 0) then
                      begin
                        SetLength(EDID, Size);
                        Reg.ReadBinaryData('EDID', EDID[0], Size);
                        Info[k].ResolutionH := ((edid[dtd+4] shr 4) shl 8) or edid[dtd+2];
                        Info[k].ResolutionV := ((edid[dtd+7] shr 4) shl 8) or edid[dtd+5];
                        Info[k].SizeH := (((Edid[dtd+14] shr 4) shl 8) + Edid[dtd+12]) / 10;   //    Info[k].SizeH := edid[21];   //ok but less accurate
                        Info[k].SizeV := (((Edid[dtd+14] and 15) shl 8) + Edid[dtd+13]) / 10;  //     Info[k].SizeV := edid[22];   //ok but less accurate
                        Info[k].SizeHInch := edid[21] /2.54;
                        Info[k].SizeVInch := edid[22] /2.54;
                        Info[k].AspectRatio := Info[k].SizeH / Info[k].SizeV;
                        AspDiv := GGT(Info[k].ResolutionH, Info[k].ResolutionV);
                        Info[k].AspectRatioH := Info[k].ResolutionH div AspDiv;
                        Info[k].AspectRatioV := Info[k].ResolutionV div AspDiv;
                        Info[k].AspectRatioStr := Format('%d:%d (%f:1)', [Info[k].AspectRatioH, Info[k].AspectRatioV, Info[k].AspectRatio]);
                        Diag := Sqrt(Info[k].SizeH*Info[k].SizeH + Info[k].SizeV*Info[k].SizeV);
                        Info[k].Diagonal := Diag * 1/2.54;
                        Info[k].PPI := Sqrt(Info[k].ResolutionH*Info[k].ResolutionH + Info[k].ResolutionV*Info[k].ResolutionV) / Info[k].Diagonal;
                        Info[k].DotPitch := Info[k].Diagonal / Sqrt(Info[k].ResolutionH*Info[k].ResolutionH + Info[k].ResolutionV*Info[k].ResolutionV) * 25.4;
                        Info[k].ManufactureYear := 1990 + edid[17];
                        Info[k].Manufacturer := DecodeManufacturer(Edid[8] shl 8 + Edid[9]);
                      end;
                  end;
              end;
        finally
          Reg.Free;
        end;
      end;
    finally
      Keys.Free;
    end;

  finally
    Result := Monitors.Count > 0;
    Monitors.Free;
  end;
end;

end.
