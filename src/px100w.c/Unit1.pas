unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TForm1 = class(TForm)
    ListBox1: TListBox;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    CheckBox1: TCheckBox;
    Label5: TLabel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    function initCOM(st1: string):boolean;
    procedure px100_scan(px100_port:string;stop_mA,step_10mA:integer);
  end;

const
  fBinary = $0001;
  fParity = $0002;
  fOutxCtsFlow = $0004;
  fOutxDsrFlow = $0008;
  fDtrControlDisable = DTR_CONTROL_DISABLE shl 4;
  fDtrControlEnable = DTR_CONTROL_ENABLE shl 4;
  fDtrControlHandshake = DTR_CONTROL_HANDSHAKE shl 4;
  fDsrSensitivity = $0040;
  fTXContinueOnXoff = $0080;
  fOutX = $0100;
  fInX = $0200;
  fErrorChar = $0400;
  fNull = $0800;
  fRtsControlDisable = RTS_CONTROL_DISABLE shl 12;
  fRtsControlEnable = RTS_CONTROL_ENABLE shl 12;
  fRtsControlHandshake = RTS_CONTROL_HANDSHAKE shl 12;
  fRtsControlToggle = RTS_CONTROL_TOGGLE shl 12;
  fAbortOnError = $4000;

var
  Form1: TForm1;
  com_str:string;
  h1:hfile;
  cc:Tcommconfig;
  debug1:integer=1;  

implementation

{$R *.DFM}

procedure delayms(w1: word);
var
  hcat1 : THandle;
  dwres:dword;
begin
  hcat1:=CreateEvent( nil, //不使用SECURITY_ATTRIBUTES結構
                      FALSE, //不自動重置
                      false, //設置初始值
                      'cat1' //事件對象的名稱
                      );
  if hcat1 = 0 then
  begin
    Showmessage('CreateEvent failed.');
    halt(1);
  end;
  dwRes := WaitForSingleObject( hcat1, w1);
  CloseHandle(hcat1);
end;
function TForm1.initCOM(st1: string):boolean;
begin
  result:=false;
  com_str:='\\.\COM'+st1;
  h1:=createfile(pchar(com_str), generic_read or generic_write,0,nil,open_existing,0,0);
  if (h1=invalid_handle_value) then
  begin
    //writeln('Fail to Open ...');
    listbox1.Items.Add('Fail to Open ...');
    application.ProcessMessages;
    //halt(1);
    exit;
  end;

  //writeln(com_str+' open ok');
  listbox1.Items.Add(com_str+' open ok');
  application.ProcessMessages;
  getcommstate(h1,cc.dcb);
  cc.dcb.baudrate:=CBR_9600;
  cc.dcb.bytesize:=8;
  cc.dcb.parity:=noparity;
  cc.dcb.stopbits:=ONESTOPBIT;
  cc.dcb.Flags:= fBinary or fDtrControlDisable or fRtsControlDisable;


  if setcommstate(h1,cc.dcb) then
  begin
    //writeln(com_str+' initial ok');
    listbox1.Items.Add(com_str+' initial ok');
    application.ProcessMessages;
  end
  else
  begin
    listbox1.Items.Add(com_str+' initial fail');
    application.ProcessMessages;
    //writeln(com_str+' initial fail');
    //halt(2);
    exit;
  end;
  result:=true;
end;

procedure close_COM;
begin
  fileclose(h1);
end;

procedure rx1;
var
  dwErrorFlags,dwLength : DWORD;
  //CommState : ComStat;
  CommState : TComStat;
  InputBuffer : Array [1..1024] of Char;
  st1,st2:string;
  i1:integer;
begin
  st2:='';
  st1:='';
  i1:=0;
  ClearCommError(h1, dwErrorFlags,@CommState);
  while (CommState.cbInQue <1) do
  begin
    inc(i1);
    delayms(10);
    ClearCommError(h1, dwErrorFlags,@CommState);  
  end;
  if debug1>100 then
  begin
    //writeln('wait='+inttostr(i1));
    //writeln('n Read='+inttostr(CommState.cbInQue));
    Form1.listbox1.Items.Add('wait='+inttostr(i1));
    Form1.listbox1.Items.Add('n Read='+inttostr(CommState.cbInQue));
    application.ProcessMessages;
  end;

  if CommState.cbInQue>sizeof(InputBuffer) then
    CommState.cbInQue:=0;

  if CommState.cbInQue>0 then
  begin
    ReadFile(h1,InputBuffer,CommState.cbInQue,dwLength, nil);
    for i1:=1 to CommState.cbInQue do
    begin
      st1:=st1+format('%0.2x-',[ord(InputBuffer[i1])]);
    end;
    if debug1>100 then
    begin
//      writeln(st1);
      Form1.listbox1.Items.Add(st1);
      application.ProcessMessages;
    end;
  end;

end;


function rx7:integer;
var
  dwErrorFlags,dwLength : DWORD;
  CommState : TComStat;
  InputBuffer : Array [1..1024] of Char;
  st1,st2:string;
  i1:integer;
begin
  st2:='';
  st1:='';
  i1:=0;
  ClearCommError(h1, dwErrorFlags,@CommState);
  while (CommState.cbInQue < 7) do
  begin
    inc(i1);
    delayms(10);
    ClearCommError(h1, dwErrorFlags,@CommState);
  end;
  if debug1>100 then
  begin
    //writeln('wait='+inttostr(i1));
    //writeln('n Read='+inttostr(CommState.cbInQue));
    Form1.listbox1.Items.Add('wait='+inttostr(i1));
    Form1.listbox1.Items.Add('n Read='+inttostr(CommState.cbInQue));
    application.ProcessMessages;
  end;

  if CommState.cbInQue>sizeof(InputBuffer) then
    CommState.cbInQue:=0;

  if CommState.cbInQue>0 then
  begin
    ReadFile(h1,InputBuffer,CommState.cbInQue,dwLength, nil);

    for i1:=1 to CommState.cbInQue do
    begin
      st1:=st1+format('%0.2x-',[ord(InputBuffer[i1])]);
    end;
    if debug1>100 then
    begin
      //writeln(st1);
      Form1.listbox1.Items.Add(st1);
      application.ProcessMessages;
    end;
  end;
  result:= ord(InputBuffer[3])*$10000+
        ord(InputBuffer[4])*$100+
        ord(InputBuffer[5]);
end;


procedure write_cmd(b1,b2,b3:byte);
var
  dw1:dword;
  buf:array [1..10] of byte;
  st1:string;
begin
  buf[1]:=$b1;
  buf[2]:=$b2;
  buf[3]:=b1;
  buf[4]:=b2;
  buf[5]:=b3;
  buf[6]:=$b6;
  WriteFile(h1,buf,6,dw1, nil);
end;

procedure px100_rest_counter;
begin
  if debug1>1 then
  begin
    //writeln('px100_rest_counter');
    Form1.listbox1.Items.Add('px100_rest_counter');
    application.ProcessMessages;
  end;
  write_cmd($05,$00,$00);
  rx1;
end;

procedure px100_on;
begin
  if debug1>1 then
  begin
    //writeln('px100_on');
    Form1.listbox1.Items.Add('px100_on');
    application.ProcessMessages;    
  end;
  write_cmd($01,$01,$00);
  rx1;
end;

procedure px100_off;
begin
  if debug1>1 then
  begin
    //writeln('px100_off');
    Form1.listbox1.Items.Add('px100_off');
    application.ProcessMessages;
  end;    
  write_cmd($01,$00,$00);
  rx1;
end;

procedure px100_set_A(b1,b2:integer);
begin
  if debug1>1 then
  begin
    //writeln('px100_set_A');
    Form1.listbox1.Items.Add('px100_set_A');
    application.ProcessMessages;
  end;
  //b1 is A
  //b2 is 10mA
  write_cmd($02,b1,b2);
  rx1;
end;

function px100_ask_mA:integer;
begin
  if debug1>1 then
  begin
    //writeln('px100_ask_mA');
    Form1.listbox1.Items.Add('px100_ask_mA');
    application.ProcessMessages;    
  end;
  write_cmd($12,0,0);
  result:=rx7;
  if debug1>10 then
  begin
    //writeln(result);
    Form1.listbox1.Items.Add(inttostr(result));
    application.ProcessMessages;    
  end;
end;

function px100_ask_mV:integer;
begin
  if debug1>1 then
  begin
    //writeln('px100_ask_mV');
    Form1.listbox1.Items.Add('px100_ask_mV');
    application.ProcessMessages;
  end;
  write_cmd($11,0,0);
  result:=rx7;
  if debug1>10 then
  begin
    //writeln(result);
    Form1.listbox1.Items.Add(inttostr(result));
    application.ProcessMessages;    
  end;
end;


procedure TForm1.Button2Click(Sender: TObject);
begin
  listbox1.Items.Clear;
end;

procedure show_last;
begin
  Form1.listbox1.ItemIndex:=Form1.listbox1.Items.Count-1;
  application.ProcessMessages;
end;

function str_now:string;
var
  i1,hh,mm,ss,ms:integer;
  st1:string;
begin
  i1:=DateTimeToTimeStamp(Now).time;

  ms:=i1 mod (1000);
  i1:=i1 div 1000;

  ss:=i1 mod 60;
  i1:=i1 div 60;

  mm:=i1 mod 60;
  i1:=i1 div 60;

  hh:=i1;

  result:=inttostr(hh)+'.'+
                       inttostr(mm)+'.'+
                       inttostr(ss)+'.'+
                       inttostr(ms);                       
end;

procedure TForm1.px100_scan(px100_port:string;stop_mA,step_10mA:integer);
var
  A_now,A1000,A10:integer;
  act_A,act_V:integer;
  st1:string;
  f1:textfile;
  fname:string;
begin
  //initCOM('19');
  if not initCOM(px100_port) then
    exit;

  if checkbox1.Checked then
    fname:='px100.'+str_now+'.log'
  else
    fname:='px100.log';

  Form1.listbox1.Items.Add(fname);
  show_last;


  assignfile(f1,fname);
  rewrite(f1);

  px100_off;
  delayms(500);
  px100_rest_counter;
  delayms(500);
  px100_set_A(0,0);
  delayms(500);
  px100_on;
  show_last;
  delayms(1000);
  A_now:=0;

  repeat

    act_V:=px100_ask_mV;
    act_A:=px100_ask_mA;
    st1:='Set '+inttostr(A_now)+' mA V='+
        inttostr(act_V)+' mV A='+
        inttostr(act_A)+' mA';
    //writeln(st1);
    Form1.listbox1.Items.Add(st1);
    show_last;
    writeln(f1,st1);
    A_now:=A_now + (step_10mA* 10);
    if (A_now < 10000) and (A_now<=stop_mA) then
    begin
      px100_set_A((A_now div 1000),(A_now mod 1000) div 10);
      if debug1>10 then
      begin
        //writeln('set ',(A_now div 1000),' ',(A_now mod 1000) div 10);
        Form1.listbox1.Items.Add('set '+inttostr(A_now div 1000)+' '+inttostr((A_now mod 1000) div 10));
        show_last;
      end;
      delayms(1000);
    end;
    show_last;
  until A_now>stop_mA;
  px100_off;
  delayms(100);
  px100_set_A(0,0);  
  if debug1>10 then
  begin
    //writeln('#########');
    listbox1.Items.Add('#########');
    show_last;
  end;
  close_COM;
  closefile(f1); 
end;
procedure TForm1.Button1Click(Sender: TObject);
begin
    debug1:=strtoint(edit4.Text);
    px100_scan(edit1.Text,strtoint(edit2.Text),strtoint(edit3.Text));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Top:=0;
  form1.Left:=0;
end;



end.
