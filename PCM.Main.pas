unit PCM.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Registry,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  IdHTTPWebBrokerBridge, Web.HTTPApp, IdContext, IdSSLOpenSSL,
  Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.UI, FireDAC.Comp.DataSet, IdCustomTCPServer, IdCustomHTTPServer,
  IdHTTPServer, ZipForge,inifiles,system.DateUtils, REST.Types, REST.Client,
  REST.Authenticator.Basic, Data.Bind.Components, Data.Bind.ObjectScope;
type
  TAufgabenThread = class(TThread)
  private
    { Private-Deklarationen }
  protected
    procedure Execute; override;
  public
    Proc: TProcedure;
end;
type
  TPCM_Service = class(TService)
    FDManager: TFDManager;
    ZipForge1: TZipForge;
    qryTermine: TFDQuery;
    Timer1: TTimer;
    Timer2: TTimer;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    HTTPBasicAuthenticator1: THTTPBasicAuthenticator;
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private-Deklarationen }
    function BerechneNaechstenZeitpunkt(AZeitTyp, AZeit1, AZeit2: Integer; AZeit3: TDatetime): TDatetime;
  public
    { Public-Deklarationen }
    function GetServiceController: TServiceController; override;
    procedure TerminAusfuehren;
  end;

var
  PCM_Service: TPCM_Service;
  dtDateTime: tDateTime;
  fINI: TextFile;
  filename: String;
  CustomTaskID: Integer;

implementation

{$R *.dfm}

uses  PCM.Functions,
      PCM.Data,
      PCM.Functions.Server.Methods,
      IdGlobal;

procedure CustomTask;
var
  IniFile: TIniFile;
  Name, Cmd: string;
begin
  if CustomTaskID > 0 then
  begin
    IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'PCMService.ini');
    Name := IniFile.ReadString('CustomTasks',
      'Name' + IntToStr(CustomTaskID), '');
    Cmd := IniFile.ReadString('CustomTasks',
      'Command' + IntToStr(CustomTaskID), '');
    IniFile.Free;
    if Cmd <> '' then
    begin
      Writelog(PCM_LOGName,'Aufruf von ' + Name,2);
//      ExecuteAndWaitFor(Cmd);
    end;
  end;
end;
procedure TAufgabenThread.Execute;
begin
  try
    Proc;
  except
    on E: Exception do
      Writelog(PCM_logname,'Exception: ' + E.Message, 2);
  end;
end;
procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  PCM_Service.Controller(CtrlCode);
end;
function TPCM_Service.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;
function TPCM_Service.BerechneNaechstenZeitpunkt(AZeitTyp, AZeit1, AZeit2: Integer; AZeit3: TDatetime): TDatetime;
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
procedure TPCM_Service.TerminAusfuehren;
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
begin
  try
    Writelog(PCM_Logname,'Termin ' + qryTermine.FieldByName('Name').AsString + ' wird ausgeführt.',0);
    dm_PCM.qry_Service.SQL.Text := 'SELECT * FROM service_Aufgaben WHERE ID_Termine = :ID_Termine ORDER BY Reihenfolge ASC';
    dm_PCM.qry_Service.ParamByName('ID_Termine').AsInteger := qryTermine.FieldByName('ID').AsInteger;
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
    Writelog(PCM_logname,'Nächsten Zeitpunkt setzen',0);
    qryTermine.Edit;
    qryTermine.FieldByName('NaechsterZeitpunkt').AsDateTime :=
      BerechneNaechstenZeitpunkt(
        qryTermine.FieldByName('ZeitTyp').AsInteger,
        qryTermine.FieldByName('Zeit1').AsInteger,
        qryTermine.FieldByName('Zeit2').AsInteger,
        qryTermine.FieldByName('Zeit3').AsDateTime);
    qryTermine.Post;
  except
    on E: Exception do
      Writelog(PCM_logname,'Exception beim Ausführen des Termins "' +
        qryTermine.FieldByName('Name').AsString + '": ' + E.Message,2);
  end;
end;
procedure TPCM_Service.ServiceAfterInstall(Sender: TService);
var
  reg: TRegistry;
begin
  reg := TRegistry.Create(KEY_READ or KEY_Write);
  try
    reg.RootKey:= HKEY_LOCAL_MACHINE;
    Writelog(PCM_Logname,'Erstelle Registryeinträge',0);
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
    WriteLog(PCM_LOGname,'Verbindung erfolgreich hergestellt',0);
    WriteLog(PCM_LOGname,'HD-ID:'+ IntToStr(dm_PCM.iHDID),0);
    WriteLog(PCM_LOGname,'PC-ID:'+ dm_PCM.sPCID,0);
    Timer1.Enabled:= true;
  end;
end;
procedure TPCM_Service.Timer1Timer(Sender: TObject);
var
  Jetzt: TDatetime;
begin
  if not qryTermine.Active then
  begin
    Timer1.Interval := 1000;
    qryTermine.SQL.Text := 'SELECT * FROM Service_Termine WHERE :PCID or  HDID = :HDID' ;
    qryTermine.ParamByName('PCID').asString := dm_PCM.sPCID ;
    qryTermine.ParamByName('HDID').asInteger := dm_PCM.iHDID;
    qryTermine.Open;
    try
      while not qryTermine.Eof do
      begin
        Jetzt := Now;
        if qryTermine.FieldByName('NaechsterZeitpunkt').AsDateTime <> 0 then
          if qryTermine.FieldByName('NaechsterZeitpunkt').AsDateTime <= Jetzt then
          begin
            try
              TerminAusfuehren;
            except
              on e:Exception do
              begin
                WriteLog(PCM_Logname,e.Message,2);
                qryTermine.Close;
                raise;
              end;
            end;
          end;
        qryTermine.Next;
      end;
    finally
      qryTermine.Close;
    end;
  end;
end;
procedure TPCM_Service.Timer2Timer(Sender: TObject);
begin
//  Backup(Sender);
 //( BackupDatabase;
end;
end.
