unit MainUnit;

{ written by Glenn9999 @ tek-tips.com.  Posted here 6/21/2011 }
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  Tmonitorthread = class(TThread)  // pipe monitoring thread for console output
  private
    TextString: String;
    procedure UpdateCaption;
  protected
    procedure Execute; override;
  end;

  TMainForm = class(TForm)
    procedure FormDestroy(Sender: TObject);
    procedure StartMiningNow;
  private
    { Private declarations }
  public
    { Public declarations }
    address,urlstr:ansistring;
  end;

var
  MainForm: TMainForm;
  windowshandleqt:HWND;
  InputPipeRead, InputPipeWrite: THandle;
  OutputPipeRead, OutputPipeWrite: THandle;
  ErrorPipeRead, ErrorPipeWrite: THandle;
  ProcessInfo : TProcessInformation;
  myThread: Tmonitorthread;

implementation

{$R *.DFM}

function ReadPipeInput(InputPipe: THandle; var BytesRem: Integer): String;
  {
    reads console output from InputPipe.  Returns the input in function
    result.  Returns bytes of remaining information to BytesRem
  }
  var
    TextBuffer: array[1..32767] of AnsiChar;// char;
    TextString: String;
    BytesRead: Cardinal;
    PipeSize: Integer;
  begin
    Result := '';
    PipeSize := length(TextBuffer);
    // check if there is something to read in pipe
    PeekNamedPipe(InputPipe, nil, PipeSize, @BytesRead, @PipeSize, @BytesRem);
    if bytesread > 0 then
      begin
        ReadFile(InputPipe, TextBuffer, pipesize, bytesread, nil);
        // a requirement for Windows OS system components
        OemToChar(@TextBuffer, @TextBuffer);
        TextString := String(TextBuffer);
        SetLength(TextString, BytesRead);
        Result := TextString;
      end;
  end;

procedure Tmonitorthread.Execute;
{ monitor thread execution for console output.  This must be threaded.
   checks the error and output pipes for information every 40 ms, pulls the
   data in and updates the memo on the form with the output }
var
  BytesRem: integer;
begin
  while not Terminated do
    begin
      // read regular output stream and put on screen.
      TextString := ReadPipeInput(OutputPipeRead, BytesRem);
      if TextString <> '' then
         Synchronize(UpdateCaption);
      // now read error stream and put that on screen.
      TextString := ReadPipeInput(ErrorPipeRead, BytesRem);
      if TextString <> '' then
         Synchronize(UpdateCaption);
      sleep(40);
    end;
end;

procedure sendstringtoQT(ansistr:ansistring);
var
  str:PAnsichar;
  copyDataStruct : TCopyDataStruct;
begin
  str:=strnew(PAnsiChar(ansistr));

  copyDataStruct.dwData := 0;
  copyDataStruct.cbData := 1 + Length(str);
  copyDataStruct.lpData := str;

  sendmessage(windowshandleqt, WM_COPYDATA,0, nativeuint(@copyDataStruct));
  StrDispose(str);
end;



procedure Tmonitorthread.UpdateCaption;
// synchronize procedure for monitor thread - updates memo on form.
var str:TStringList;
  x:integer;
begin
  str:=TStringList.create;
  str.text:=TextString;
  for x:=0 to str.count-1 do
  sendstringtoQT(str[x]);
  str.destroy;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MyThread.Terminate;
  // close process handles
  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
  // close pipe handles
  CloseHandle(InputPipeRead);
  CloseHandle(InputPipeWrite);
  CloseHandle(OutputPipeRead);
  CloseHandle(OutputPipeWrite);
  CloseHandle(ErrorPipeRead);
  CloseHandle(ErrorPipeWrite);
end;

procedure TMainForm.StartMiningNow;
var adr,url: PAnsiChar;
    DosApp: string;
    Security : TSecurityAttributes;
    start : TStartUpInfo;

begin
  if paramcount=3 then begin
    try
      windowshandleqt:=strtoint(paramstr(1));
    except
    end;
    address:=paramstr(2);
    urlstr:=paramstr(3);

    DosApp := 't-rex -a x16r -o '+urlstr+' -u '+address;

  // create pipes
    With Security do
      begin
        nlength := SizeOf(TSecurityAttributes) ;
        binherithandle := true;
        lpsecuritydescriptor := nil;
      end;
    CreatePipe(InputPipeRead, InputPipeWrite, @Security, 0);
    CreatePipe(OutputPipeRead, OutputPipeWrite, @Security, 0);
    CreatePipe(ErrorPipeRead, ErrorPipeWrite, @Security, 0);

  // start command-interpreter
    FillChar(Start,Sizeof(Start),#0) ;
    start.cb := SizeOf(start) ;
    start.hStdInput := InputPipeRead;
    start.hStdOutput := OutputPipeWrite;
    start.hStdError :=  ErrorPipeWrite;
    start.dwFlags := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
    start.wShowWindow := SW_HIDE;
    if CreateProcess(nil, @DosApp[1], @Security, @Security, true,
               CREATE_NEW_CONSOLE or SYNCHRONIZE,
               nil, nil, start, ProcessInfo) then
      begin
        MyThread := Tmonitorthread.Create(false);  // start monitor thread
        MyThread.Priority := tpHigher;
      end;

  end;
end;


 end.
