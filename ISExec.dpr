library ISExec;

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  OtlTask,
  OtlTaskControl,
  OtlCommon;

{$R *.res}

type
  TCancelProc = function: Boolean of object;

procedure ExecTask(const task: IOmniTask);

  function _Win32Check(RetVal: BOOL): BOOL;
  begin
    if not RetVal then
      begin
        OutputDebugString(PChar(SysErrorMessage(GetLastError)));
      end;
    Result := RetVal;
  end;

 var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CmdLine: UnicodeString;
  CancelProc: TMethod;
begin
  CancelProc := task.Param['Callback'].ToRecord<TMethod>;
  CmdLine := task.Param['ExeName'];
  UniqueString(CmdLine);

  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;

  if task.Param['Visible'] then
    SI.wShowWindow := SW_SHOWNORMAL
  else
    SI.wShowWindow := SW_HIDE;

  SetLastError(ERROR_INVALID_PARAMETER);
  {$WARN SYMBOL_PLATFORM OFF}
  _Win32Check(CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_DEFAULT_ERROR_MODE {$IFDEF UNICODE}or CREATE_UNICODE_ENVIRONMENT{$ENDIF}, nil, nil, SI, PI));
  {$WARN SYMBOL_PLATFORM ON}
  WaitForInputIdle(PI.hProcess, INFINITE);
  CloseHandle(PI.hThread);
  while (WaitForSingleObject(PI.hProcess, 10) <> WAIT_OBJECT_0) do
    begin
      if TCancelProc(CancelProc) then
        begin
          TerminateProcess(PI.hProcess, 0);
          task.Terminate;
        end;
    end;
  CloseHandle(PI.hProcess);
end;

procedure Exec(aEXEName: WideString; aVisible: Boolean; aCallback: TMethod); stdcall;
 var
  lTask: IOmniTaskControl;
  Msg: TMsg;
begin
  lTask := CreateTask(ExecTask)
    .SetParameter('ExeName', aEXEName)
    .SetParameter('Callback', TOmniValue.FromRecord<TMethod>(aCallback))
    .SetParameter('Visible', aVisible)
    .Run;
  while not lTask.WaitFor(10) do
    begin
      while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
        begin
          TranslateMessage(Msg);
          DispatchMessage(Msg);
        end;
    end;
end;

exports
   Exec;

begin
end.
