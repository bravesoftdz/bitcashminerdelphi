unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    procedure sendstringtoQT(ansistr:ansistring);
    procedure StartMiningNow;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    windowshandleqt:HWND;
    address,urlstr:ansistring;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}
type
  TCallBack = procedure(text:PAnsiChar); cdecl;

function startmining(address:PAnsiChar; url:PAnsiChar) : Integer;cdecl; external 'ccminer.dll';
function stopmining : Integer;cdecl; external 'ccminer.dll';
procedure setcallback( p:TCallBack );cdecl; external 'ccminer.dll';

procedure applog(text:PAnsiChar); cdecl;
begin
  mainform.sendstringtoQT(text);
end;

procedure TMainForm.sendstringtoQT(ansistr:ansistring);
var
  str:PAnsichar;
  copyDataStruct : TCopyDataStruct;
begin
  setcallback(applog);

  str:=strnew(PAnsiChar(ansistr));

  copyDataStruct.dwData := 0;
  copyDataStruct.cbData := 1 + Length(str);
  copyDataStruct.lpData := str;

  sendmessage(windowshandleqt, WM_COPYDATA,0, nativeuint(@copyDataStruct));
  StrDispose(str);
end;

procedure TMainForm.StartMiningNow;
var adr,url: PAnsiChar;
begin
  if paramcount=3 then begin
    try
      windowshandleqt:=strtoint(paramstr(1));
    except
    end;
    address:=paramstr(2);
    urlstr:=paramstr(3);

    setcallback(applog);
    adr := StrNew(PAnsiChar(address));
    url := StrNew(PAnsiChar(urlstr));
    startmining(adr,url);
    StrDispose(adr);
    StrDispose(url);
  end;
end;

end.
