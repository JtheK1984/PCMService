unit PCM.Main;

interface

uses
  {$Region Uses}
  Data.Bind.Components,
  Data.Bind.ObjectScope,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.UI,
  FireDAC.DApt,
  FireDAC.DApt.Intf,
  FireDAC.DatS,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Pool,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  IdBaseComponent,
  IdComponent,
  IdContext,
  IdCustomHTTPServer,
  IdCustomTCPServer,
  IdHTTPServer,
  IdHTTPWebBrokerBridge,
  IdIOHandler,
  IdIOHandlerSocket,
  IdIOHandlerStack,
  IdSSL,
  IdSSLOpenSSL,
  inifiles,
  Registry,
  REST.Authenticator.Basic,
  REST.Client,
  REST.Types,
  System.Classes,
  system.DateUtils,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.SvcMgr,
  Web.HTTPApp,
  Winapi.Messages,
  Winapi.Windows;
  {$EndRegion Uses}
type
  {$Region Type}
  TAufgabenThread = class(TThread)
  private
    { Private-Deklarationen }
  protected
    procedure Execute; override;
  public
    Proc: TProcedure;
  end;

  TPCM_Service = class(TService)
    fdmgr_PCMService: TFDManager;
    physdvrLnk_Mysql: TFDPhysMySQLDriverLink;
    qry_Termine: TFDQuery;
    tmr_BackupDatabase: TTimer;
    tmr_Service: TTimer;
    wtCsr_Mysql: TFDGUIxWaitCursor;
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure tmr_BackupDatabaseTimer(Sender: TObject);
    procedure tmr_ServiceTimer(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    dtDateTime: tDateTime;
    iCustomTaskID: Integer;
    filename: String;
    fINI: TextFile;
    function GetServiceController: TServiceController; override;
    procedure TerminAusfuehren;
  end;
  {$EndRegion type}
var
  PCM_Service: TPCM_Service;


implementation

{$R *.dfm}

uses
      PCM.Data,
      PCM.Functions,
      PCM.Functions.Server.Methods,
      PCM.Strings;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  PCM_Service.Controller(CtrlCode);
end;
function TPCM_Service.GetServiceController: TServiceController;

begin
  Result := ServiceController;
end;
procedure TAufgabenThread.Execute;
begin
  try
    Proc;
  except
    on E: Exception do
      Writelog(PCM_logname,rs_PCM_Exception + E.Message, 2);
  end;
end;
procedure TPCM_Service.ServiceAfterInstall(Sender: TService);
var
  reg: TRegistry;
begin
  reg := TRegistry.Create(KEY_READ or KEY_Write);
  try
    reg.RootKey:= HKEY_LOCAL_MACHINE;
    Writelog(PCM_Logname,rs_PCMRestserver_Registry,0);
    if reg.OpenKey('System\CurrentControlSet\Services\PCM_Service',False) then
      reg.WriteString('Description','Allgemeiner Dienst für PCM');
  finally
    reg.Free;
  end;
end;
procedure TPCM_Service.ServiceStart(Sender: TService;var Started: Boolean);
begin
  if dm_PCM.ReadServerAdress then
  begin
    WriteLog(PCM_LOGname,rs_Function_Helper_Verbindungerfolgreich,0);
    WriteLog(PCM_LOGname,rs_PCMService_HIID + IntToStr(dm_PCM.iHDID),0);
    WriteLog(PCM_LOGname,rs_PCMService_PCID + dm_PCM.sPCID,0);
    tmr_Service.Enabled:= true;
  end;
end;
procedure TPCM_Service.TerminAusfuehren;
  function BerechneNaechstenZeitpunkt(AZeitTyp, AZeit1, AZeit2: Integer; AZeit3: TDatetime): TDatetime;
  var
    Jetzt, Heute: TDatetime;
    Year, Month, Day, Hour, Min, Sec, MSec: Word;
    WeekDay, NextWeekDay, Diff: Integer;
  begin
    Jetzt := Now;
    Heute := Date;

    DecodeTime(Jetzt, Hour, Min, Sec, MSec);
    DecodeDate(Jetzt, Year, Month, Day);
    case AZeitTyp of
      // Minuten
      // Jetzt + n Minuten
      0:
        Result := IncMinute(Jetzt, AZeit1);
      // Stunden
      // Datum von Heute + Momentane Stunde + n Stunden + n Minuten
      1:
        Result :=
        // Geändert 2202021454 konnte Exception erzeugen, wenn um 23:00 um eine Stunde erhöht wird
          IncMinute(IncHour(Heute, Hour + AZeit1), AZeit2);
      // Täglich
      2:
        begin
          // Heute + Zeitpunkt
          Result := Heute + AZeit3;
          // Schon vorbei?
          if Result < Jetzt then
            // -> Tag um eins erhöhen
            Result := IncDay(Result, 1);
        end;
      // Wöchentlich
      3:
        begin
          // Heutiger Wochentag (1 bis 7)
          WeekDay := DayOfWeek(Heute);
          Dec(WeekDay);
          if WeekDay = 0 then
            WeekDay := 7;
          // Nächster Wochentag (1 bis 7)
          NextWeekDay := AZeit1;
          // Differenz an Tagen ausrechnen
          if WeekDay > NextWeekDay then
            Diff := NextWeekDay + 7 - WeekDay
          else
            Diff := NextWeekDay - WeekDay;

          // Heute + Tagdifferenz + Zeitpunkt
          Result := IncDay(Heute, Diff) + AZeit3;
          // Schon vorbei?
          if Result < Jetzt then
            // Nächste Woche
            Result := IncDay(Result, 7);
        end;
      // Monatlich
      4:
        begin
          // n. Tag des aktuellen Monats, zur angegebenen Zeit
          Result := EncodeDate(Year, Month, AZeit1) + AZeit3;
          // Schon vorbei?
          if Result < Jetzt then
            // Nächster Monat
            Result := IncMonth(Result, 1);
        end;
      // Manuell
      5:
        begin
          Result := 0;
        end;
      // Sekunden
      6:
        begin
          Result := IncSecond(Jetzt, AZeit1);
        end;
    else
      Result := 0;
    end;
  end;
  procedure Execute(What: TProcedure);
  var
    Thread: TAufgabenThread;
  begin
    Thread := TAufgabenThread.Create(True);
    Thread.Proc := What;
    Thread.Start;
    while WaitForSingleObject(Thread.Handle, 10) = WAIT_TIMEOUT do
      ServiceThread.ProcessRequests(False);
    Thread.Free;
  end;
  procedure CustomTask;
  var
    IniFile: TIniFile;
    Name, Cmd: string;
  begin
    if iCustomTaskID > 0 then
    begin
      IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'PCMService.ini');
      Name := IniFile.ReadString('CustomTasks',
        'Name' + IntToStr(iCustomTaskID), '');
      Cmd := IniFile.ReadString('CustomTasks',
        'Command' + IntToStr(iCustomTaskID), '');
      IniFile.Free;
      if Cmd <> '' then
      begin
        Writelog(PCM_LOGName,rs_PCMService_Aufrufvon + Name,2);
  //      ExecuteAndWaitFor(Cmd);
      end;
    end;
  end;
begin
  try
    Writelog(PCM_Logname,rs_PCMService_Termin1 + qry_Termine.FieldByName('Name').AsString + rs_PCMService_Termin2,0);
    dm_PCM.qry_Service.SQL.Text := 'SELECT * FROM service_Aufgaben WHERE ID_Termine = :ID_Termine ORDER BY Reihenfolge ASC';
    dm_PCM.qry_Service.ParamByName('ID_Termine').AsInteger := qry_Termine.FieldByName('ID').AsInteger;
    dm_PCM.qry_Service.Open;
    while not dm_PCM.qry_Service.Eof do
    begin
      case dm_PCM.qry_Service.FieldByName('Typ').AsInteger of
        1:
        begin
          Writelog(PCM_Logname,'Aufgabe automatisches Herunterfahren wird ausgeführt.',0);
          Execute(Shutdown);
        end;
        2:
        begin
          // Datensicherung
//          Execute(MonateBerechnen);
        end;
        3:
        begin
          // Datenbanksicherung
          Writelog(PCM_Logname,'Aufgabe Datenbanksicherung wird ausgeführt.',0);
          Execute(BackupDatabase);
//            ZMIDebugMsg('Aufruf von Aufträge berechnen');
          //Execute(AuftraegeBerechnen);
        end;
        4:
        begin
          Writelog(PCM_Logname,'Aufgabe Quellcodesicherung wird ausgeführt.',0);
          Execute(BackupQuellcode)
        end;
        5:
        begin
          Writelog(PCM_Logname,'Aufgabe Pushnotification wird ausgeführt.',0);
          Execute(SendPushNotification)
        end;

      else
        begin
//          CustomTaskID := qWork.FieldByName('Typ').AsInteger - 100;
//          Execute(CustomTask);
        end;
      end;
      dm_PCM.qry_Service.Next;
    end;
    dm_PCM.qry_Service.Close;
    Writelog(PCM_logname,rs_PCMService_NaechsterZeitpunktSetzen,0);
    qry_Termine.Edit;
    qry_Termine.FieldByName('NaechsterZeitpunkt').AsDateTime :=
      BerechneNaechstenZeitpunkt(
        qry_Termine.FieldByName('ZeitTyp').AsInteger,
        qry_Termine.FieldByName('Zeit1').AsInteger,
        qry_Termine.FieldByName('Zeit2').AsInteger,
        qry_Termine.FieldByName('Zeit3').AsDateTime);
    qry_Termine.Post;
  except
    on E: Exception do
      Writelog(PCM_logname,rs_PCMService_ExceptionTermin +
        qry_Termine.FieldByName('Name').AsString + '": ' + E.Message,2);
  end;
end;
procedure TPCM_Service.tmr_ServiceTimer(Sender: TObject);
var
  Jetzt: TDatetime;
begin
  if not qry_Termine.Active then
  begin
    tmr_Service.Interval := 1000;
    qry_Termine.SQL.Text := 'SELECT * FROM Service_Termine WHERE :PCID or  HDID = :HDID' ;
    qry_Termine.ParamByName('PCID').asString := dm_PCM.sPCID ;
    qry_Termine.ParamByName('HDID').asInteger := dm_PCM.iHDID;
    qry_Termine.Open;
    try
      while not qry_Termine.Eof do
      begin
        Jetzt := Now;
        if qry_Termine.FieldByName('NaechsterZeitpunkt').AsDateTime <> 0 then
          if qry_Termine.FieldByName('NaechsterZeitpunkt').AsDateTime <= Jetzt then
          begin
            try
              TerminAusfuehren;
            except
              on e:Exception do
              begin
                WriteLog(PCM_Logname,e.Message,2);
                qry_Termine.Close;
                raise;
              end;
            end;
          end;
        qry_Termine.Next;
      end;
    finally
      qry_Termine.Close;
    end;
  end;
end;
procedure TPCM_Service.tmr_BackupDatabaseTimer(Sender: TObject);
begin
//  Backup(Sender);
 //( BackupDatabase;
end;
end.
