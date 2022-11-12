# GetMonitorsInfo
Returns Resolution, Diagonal and PPI of active monitors

## Requirements
Delphi 7+, Lazarus

## Operating system
Windows XP+

### Usage example
	var Info: TMonitorInfos;
	    Len: Integer;
	    i: Integer;
	begin
	  GetMonitorsInfo(Info, Len);
	
	  for i:=0 to Len-1 do begin
	
	    Memo1.Lines.Add( Format('Resolution: %d x %d px', [Info[i].ResolutionH, Info[i].ResolutionV]) );
	    Memo1.Lines.Add( Format('Size: %f x %f cm', [Info[i].SizeH, Info[i].SizeV]) );
	    Memo1.Lines.Add( Format('Diag: %f inch', [Info[i].Diagonal]) );
	    Memo1.Lines.Add( Format('PPI: %f ', [Info[i].PPI]) );
	    Memo1.Lines.Add( Format('Dot Pitch: %f mm', [Info[i].DotPitch]) );
	    Memo1.Lines.Add( Format('Aspect Ratio: %f:1 ', [Info[i].AspectRatio]) );
	
	    Memo1.Lines.Add( Format('Year: %d ', [Info[i].ManufactureYear]) );
	    Memo1.Lines.Add( Format('Manufacturer: %s ', [Info[i].Manufacturer]) );
	
	    Memo1.Lines.Add( Format('PNP: %s', [Info[i].PNPID]) );
	
	    Memo1.Lines.Add('-----------');
	  end;
	end;
