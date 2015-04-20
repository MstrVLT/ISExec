[Setup]
AppName=My Program
AppVersion=1.5
DefaultDirName={pf}\My Program
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\MyProg.exe
OutputDir=.

[Files]
Source: "ISExec.dll"; Flags: dontcopy nocompression

[Code]

type
  TCancelFunc = function: Boolean;

procedure Exec(aEXEName: WideString; aVisible: Boolean; aCallback: TCancelFunc); external 'Exec@files:ISExec.dll stdcall';

function CallMe: Boolean;
begin
  Result := False;
end;

function NextButtonClick(CurPage: Integer): Boolean;
begin
  Log (IntToStr(CurPage));
  if CurPage = wpWelcome then 
  begin
    Exec('cmd.exe', True, @CallMe);
  end;
  Result := True;
end;
