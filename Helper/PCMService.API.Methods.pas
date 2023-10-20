unit PCMService.API.Methods;

interface

uses
  System.JSON,
  Datasnap.DSSession,
  PCM.Main,
  PCM.Data,
  PCM.Functions,
  System.Dateutils,
  Data.db,
  FireDAC.Comp.Client,
  Vcl.Graphics,
  Winapi.Windows,
  Data.DBXPlatform,FireDac.Stan.Param;

  function GetIDFromTable(ATable,AValue: String) : Integer;
  function CheckTokenGueltig(sToken: String): Boolean;
  procedure ExecuteAndWaitFor(FileName: AnsiString);

  //////////////////////////////////////////////////////////////////////////////
  // WebAPI - PCM                                                             //
  //////////////////////////////////////////////////////////////////////////////
  function CreateToken_Intern: TJSONObject;
  function RefreshToken_Intern(const AJSONObject: TJSONObject): TJSONObject;
  function DeleteToken_Intern(const sToken: String;iProg: Integer): TJSONObject;
  function CreateBackup_Intern(const sToken, sPath: String): TJSONObject;
  function GetKalenderConfig_Intern(const AJSONObject: TJSONObject): TJSONObject;
  //////////////////////////////////////////////////////////////////////////////
  // APPAPI - PCM                                                             //
  //////////////////////////////////////////////////////////////////////////////
  function GetLogin_Intern: TJSONObject;
  function GetKontakte_Intern(AID_Benutzer: string): TJSONObject;
  function GetKalender_Intern(AID_Benutzer: string): TJSONObject;
  function GetPasswoerter_Intern(AID_Benutzer: string): TJSONObject;
  function GetSerials_Intern(AID_Benutzer: string): TJSONObject;
  function GetAusgaben_Intern(AID_Benutzer: string): TJSONObject;
  function GetEinnahmen_Intern(AID_Benutzer: string): TJSONObject;
var
  joResponseJSON: TJSONObject;
  joResponseJSONData: TJSONObject;
  jaDetails: TJSonArray;
implementation

uses
  System.Classes, System.SysUtils, System.StrUtils, System.NetEncoding;

procedure ExecuteAndWaitFor(FileName: AnsiString);
var
  StartupInfo: TStartupInfoA;
  ProcessInfo: TProcessInformation;
  s: AnsiString;
begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  StartupInfo.cb := Sizeof(TStartupInfo);
  // Programm muss im gleichen Verzeichnis liegen wie ZMIServer !!!
  s := AnsiString(ExtractFileDir(ParamStr(0)));
  if CreateProcessA(nil, // Anwendungsname
    PAnsiChar(FileName), // Parameter
    nil, // Security
    nil, // Security
    False,
    NORMAL_PRIORITY_CLASS, // Priorität
    nil, // Environment
    PAnsiChar(s), // Verzeichnis
    StartupInfo,
    ProcessInfo) then
  begin
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end
  else
  begin
    WriteLog(PCM_Logname,'ExecuteAndWaitFor konnte nicht ausgeführt werden. '+
                ' Error-Code '+intToStr(GetLastError),2);
  end;
end;
  // ID aus Zusatztabellen ermitteln
function GetIDFromTable(ATable,AValue: String) : Integer;
begin
  dm_PCM.qry_Work.SQL.Text := 'SELECT ID From ' + ATable + ' Where Bezeichnung = :Bezeichnung' ;
  dm_PCM.qry_Work.ParamByName('Bezeichnung').asString := AValue;
  dm_PCM.qry_Work.Open;
  if dm_PCM.qry_Work.RecordCount = 0 then
  begin
    dm_PCM.qry_Work.Close;
    dm_PCM.qry_Work.SQL.Text := 'Insert Into ' + ATable + ' (Bezeichnung) Values (:Bezeichnung)' ;
    dm_PCM.qry_Work.ParamByName('Bezeichnung').asString := AValue;
    dm_PCM.qry_Work.ExecSQL;
    dm_PCM.qry_Work.SQL.Text := 'SELECT ID From ' + ATable + ' Where Bezeichnung = :Bezeichnung' ;
    dm_PCM.qry_Work.ParamByName('Bezeichnung').asString := AValue;
    dm_PCM.qry_Work.Open;
    Result:= dm_PCM.qry_Work.FieldByName('ID').asInteger;
  end
  else
  begin
    Result:= dm_PCM.qry_Work.FieldByName('ID').asInteger;
  end;
  dm_PCM.qry_Work.Close;
end;
// Prüfen ob Token gültig ist
function CheckTokenGueltig(sToken: String): Boolean;
begin
    dm_PCM.qry_Work.SQL.Text := 'SELECT Gueltig_Bis FROM Benutzer WHERE Token = :Token and Gueltig_Bis >= :Jetzt';
    dm_PCM.qry_work.ParamByName('Token').AsString := sToken;
    dm_PCM.qry_work.ParamByName('Jetzt').AsDateTime := Now;
    dm_PCM.qry_work.Open;
    if dm_PCM.qry_work.RecordCount > 0 then
      Result := True
    else
      Result := False;
    dm_PCM.qry_work.Close;
end;
////////////////////////////////////////////////////////////////////////////////
// WebAPI - PCM                                                               //
////////////////////////////////////////////////////////////////////////////////
// Token ermitteln
function CreateToken_Intern: TJSONObject;
  function RandomString(strlength: integer): string;
  var
    temp : integer;
  begin
    randomize;
    repeat
      temp := random(122);
      if temp in [48..57{0-1}, 65..90{A-Z}, 97..122{a-z}] then
        result := result + Chr(temp);
    until length(result) = strlength;
  end;
var
  sUser, sPass, sToken: String;
  iID_MA_Stammdaten: Integer;
  joResponseJSON: TJSONObject;
  bRestAPI: boolean;
begin
  joResponseJSON:= nil;
  try
    try
      sUser := TDSSessionManager.GetThreadSession.GetData('Username');
      WriteLog(PCM_Logname,sUser,0);
      sPass := TDSSessionManager.GetThreadSession.GetData('Password');
      WriteLog(PCM_Logname,sPass ,0);
      if not Assigned(joResponseJSON) then
        joResponseJSON := TJSONObject.Create;
      dm_PCM.qry_Work.Sql.Text := 'SELECT ID, RestAPI FROM Benutzer WHERE Benutzer =:Username AND Passwort=:Password';
      dm_PCM.qry_Work.ParamByName('Username').AsString := sUser;
      dm_PCM.qry_Work.ParamByName('Password').AsString := sPass;
      dm_PCM.qry_Work.Open;
      if dm_PCM.qry_Work.RecordCount > 0 then
      begin
        iID_MA_Stammdaten := dm_PCM.qry_Work.FieldByName('ID').AsInteger;
        bRestAPI:= dm_PCM.qry_Work.FieldByName('RestAPI').asBoolean;
        if bRestAPI then
        begin
          sToken := RandomString(70);
          dm_PCM.qry_Work.Sql.Text := 'Update Benutzer Set Token = :Token, Gueltig_Bis = :Gueltig_Bis Where ID = :ID';
          dm_PCM.qry_Work.ParamByName('Token').AsString := sToken;
          dm_PCM.qry_Work.ParamByName('Gueltig_Bis').AsDateTime := IncMinute(Now, PCM_Service.RESTServerConfig.TokenTimeout);
          dm_PCM.qry_Work.ParamByName('ID').AsInteger := iID_MA_Stammdaten;
          dm_PCM.qry_Work.ExecSQL;
          iCode:= 200;
          sMessage:= 'OK';
          joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
          joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
          joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
          joResponseJSON.AddPair(TJSONPair.Create('Token', sToken));
          joResponseJSON.AddPair(TJSONPair.Create('User', sUser));
          joResponseJSON.AddPair(TJSONPair.Create('ID_User', iID_MA_Stammdaten));
        end
        else begin
          iCode:= 403;
          sMessage:= 'Forbidden';
          joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
          joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(4)));
          joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Benutzer ' + sUSer + ' nicht berechtigt.')));
        end;
      end else
      begin
        iCode:= 401;
        sMessage:= 'Unauthorized';
        joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
        joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(2)));
        joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Benutzer ' + sUSer + ' nicht gefunden oder falsches Passwort')));
      end;
    except
      on e:exception do
      begin
        iCode:= 409;
        sMessage:= 'Database Error';
        joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
        joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(3)));
        joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Verbindung zur Datenbank. Grund:' + e.Message)));
      end;
    end;
    Result := joResponseJSON;
  finally
    dm_PCM.qry_Work.Close;
  end;
end;
// Token erneuern
function RefreshToken_Intern(const AJSONObject: TJSONObject): TJSONObject;
var
  LJsonObject: TJSONObject;
  sToken: string;
begin
  LJsonObject:= nil;
  sToken:= AJSONObject.GetValue<String>('Token');
  try
    try
      if not Assigned(joResponseJSON) then
        joResponseJSON := TJSONObject.Create;
      if CheckTokenGueltig(sToken) then
      begin
          dm_PCM.qry_Work.Sql.Text := 'Update Benutzer Set Gueltig_Bis = :Gueltig_Bis Where Token = :Token';
          dm_PCM.qry_Work.ParamByName('Token').AsString := sToken;
          dm_PCM.qry_Work.ParamByName('Gueltig_Bis').AsDateTime := IncMinute(Now, PCM_Service.RESTServerConfig.TokenTimeout);
          dm_PCM.qry_Work.ExecSQL;
          iCode:= 200;
          sMessage:= 'OK';
          LJsonObject.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
          LJsonObject.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
      end
      else begin
        iCode:= 401;
        sMessage:= 'Unauthorized';
        LJsonObject.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(2)));
        LJsonObject.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Token ungültig oder abgelaufen')));
      end;
    except
      on e:exception do
      begin
        iCode:= 409;
        sMessage:= 'Database Error';
        LJsonObject.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(3)));
        LJsonObject.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Verbindung zur Datenbank. Grund:' + e.Message)));
      end;
    end;
    Result := LJsonObject;
  finally
    dm_PCM.qry_Work.Close;
  end;
end;
// Token löschen
function DeleteToken_Intern(const sToken: String;iProg: Integer): TJSONObject;
begin
  joResponseJSON:= nil;
  try
    try
      if not Assigned(joResponseJSON) then
        joResponseJSON := TJSONObject.Create;
      if CheckTokenGueltig(sToken) then
      begin
          dm_PCM.qry_Work.Sql.Text := 'Update Benutzer Set Token = '''' Where Token = :Token';
          dm_PCM.qry_Work.ParamByName('Token').AsString := sToken;
          dm_PCM.qry_Work.ExecSQL;
          iCode:= 200;
          sMessage:= 'OK';
          joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
          joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
      end
      else begin
        iCode:= 401;
        sMessage:= 'Unauthorized';
        joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(2)));
        joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Token ungültig oder abgelaufen')));
      end;
    except
      on e:exception do
      begin
        iCode:= 409;
        sMessage:= 'Database Error';
        joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(3)));
        joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Verbindung zur Datenbank. Grund:' + e.Message)));
      end;
    end;

    Result := joResponseJSON;
  finally
    dm_PCM.qry_Work.Close;
  end;
end;
// Backup erzeugen
function CreateBackup_Intern(const sToken, sPath: String): TJSONObject;
begin
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  if CheckTokenGueltig(sToken) then
  begin
    ExecuteAndWaitFor(AnsiString(ExtractFilePath(ParamStr(0)) + 'PCMBackup\PCMBackupService.exe /' + sPath));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
  end
  else begin
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(2)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Token ungültig oder abgelaufen')));
  end;
  result:= joResponseJSON;
end;
// Kalenderconfig
function GetKalenderConfig_Intern(const AJSONObject: TJSONObject): TJSONObject;
var
  qWork: TFDQuery;
  iID_Benutzer: integer;
  sToken: string;
begin
  qWork := TFDQuery.Create(nil);
  try
    iID_Benutzer := AJSONObject.GetValue<Integer>('ID_Benutzer');
    sToken := AJSONObject.GetValue<String>('Token');
    if not Assigned(joResponseJSON) then
      joResponseJSON := TJSONObject.Create;
    if CheckTokenGueltig(sToken) then
    begin
      qWork.SQL.Text := 'SELECT Kalender,Link,Benutzer,Passwort,Erinnerung,ErinnerungVor,LabelColor,FontColor FROM manager_kalender_config WHERE ID_Benutzer = :ID_Benutzer';
      qWork.ParamByName('ID_Benutzer').AsInteger := iID_Benutzer;
      qWork.Open;
      if qWork.RecordCount > 0 then
      begin
        while not qWork.Eof do
        begin
          joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
          joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
          joResponseJSON.AddPair(TJSONPair.Create('Kalender', qWork.FieldByName('Link').AsString));
          joResponseJSON.AddPair(TJSONPair.Create('Link', qWork.FieldByName('Link').AsString));
          joResponseJSON.AddPair(TJSONPair.Create('Benutzer', qWork.FieldByName('Benutzer').AsString));
          joResponseJSON.AddPair(TJSONPair.Create('Passwort', qWork.FieldByName('Passwort').AsString));
          joResponseJSON.AddPair(TJSONPair.Create('Erinnerung', TJSONBool.Create(qWork.FieldByName('Erinnerung').AsBoolean)));
          joResponseJSON.AddPair(TJSONPair.Create('ErinnerungVor', TJSONNumber.Create(qWork.FieldByName('ErinnerungVor').AsInteger)));
          joResponseJSON.AddPair(TJSONPair.Create('LabelColor', TJSONNumber.Create(qWork.FieldByName('LabelColor').AsInteger)));
          joResponseJSON.AddPair(TJSONPair.Create('FontColor', TJSONNumber.Create(qWork.FieldByName('FontColor').AsInteger)));
//          iCount := iCount + 1;
          qWork.Next;
        end;
        qWork.Close;
      end else
      begin
        joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(6)));
        joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Kein Datensatz vorhanden')));
      end;

    end else
    begin
      joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(5)));
      joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Token ungültig oder abgelaufen')));
    end;
    Result := joResponseJSON;
  finally
    qWork.Close;
    qWork.Free;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
// APP-API - PCM                                                              //
////////////////////////////////////////////////////////////////////////////////
// Login ermitteln
function GetLogin_Intern: TJSONObject;
var
  sUser, sPass: String;
begin
  joResponseJSON:= nil;
  sUser := TDSSessionManager.GetThreadSession.GetData('Username');
  sPass := TDSSessionManager.GetThreadSession.GetData('Password');
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  try
    dm_PCM.qry_Work.SQL.Text := 'SELECT ID, Benutzer, Passwort, Startseite FROM Benutzer WHERE Benutzer =:Username AND Passwort=:Password';
    dm_PCM.qry_Work.ParamByName('Username').AsString := sUser;
    dm_PCM.qry_Work.ParamByName('Password').AsString := sPass;
    dm_PCM.qry_Work.Open;
    if dm_PCM.qry_Work.RecordCount > 0 then
    begin
      iCode:= 200;
      sMessage:= 'OK';
      joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
      joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
      joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
      joResponseJSON.AddPair(TJSONPair.Create('ID_User', dm_PCM.qry_work.FieldByName('ID').asInteger));
      joResponseJSON.AddPair(TJSONPair.Create('User', sUser));
      joResponseJSON.AddPair(TJSONPair.Create('Password', sPass));
      joResponseJSON.AddPair(TJSONPair.Create('Startpage', dm_PCM.qry_work.FieldByName('Startseite').asInteger));
    end
    else
    begin
      iCode:= 401;
      sMessage:= 'Unauthorized';
      joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
      joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(1)));
      joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Benutzer ' + sUSer + ' nicht gefunden oder falsches Passwort')));
    end;
  except
    on e:exception do
    begin
      iCode:= 409;
      sMessage:= 'Database Error';
      joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
      joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(2)));
      joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Verbindung zur Datenbank. Grund:' + e.Message)));
    end;
  end;
  dm_PCM.qry_Work.Close;
  Result := joResponseJSON;
end;
// Kontakte ermitteln
function GetKontakte_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text :=  'SELECT kon.ID as Kontakte_ID ,a.Bezeichnung AS Anrede, kon.Vorname,kon.Nachname,' +
                                         'kon.Strasse_Privat,kon.PLZ_Privat,kon.Ort_Privat,'+
                                         'kon.Telefon_Privat,kon.Handy_Privat, kon.E_mail_Privat,'+
                                         'kon.Geburtsdatum, g.Bezeichnung as Geschlecht,'+
                                         'f.Bezeichnung as Familienstand, s.Bezeichnung as Staatsangehoerigkeit,'+
                                         'k.Bezeichnung as Konfession,kon.Firma,kon.Strasse_Ges,kon.PLZ_Ges,'+
                                         'kon.Ort_Ges,kon.Telefon_Ges,kon.Handy_Ges,kon.E_mail_Ges '+
                                         'FROM manager_kontakte kon '+
                                         'LEFT OUTER JOIN manager_Anrede a ON a.ID = kon.ID_Anrede '+
                                         'LEFT OUTER JOIN manager_Geschlecht g ON g.ID = kon.ID_GEschlecht '+
                                         'LEFT OUTER JOIN manager_Familienstand f ON f.ID = kon.ID_Familienstand '+
                                         'LEFT OUTER JOIN manager_Staatsangehoerigkeit s ON s.ID = kon.ID_Staatsangehoerigkeit '+
                                         'LEFT OUTER JOIN manager_Konfession k ON k.ID = kon.ID_Konfession Where kon.ID_Benutzer = :ID_Benutzer';
  dm_PCM.qry_Work.ParamByName('ID_Benutzer').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Kontakte lesen, Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
  if dm_PCM.qry_Work.RecordCount > 0 then
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
    if not Assigned(jaDetails) then
      jaDetails := TJSONArray.Create;
    while not dm_PCM.qry_work.eof do
    begin
      if not Assigned(joResponseJSONData) then
        joResponseJSONData := TJSONObject.Create;
      joResponseJSONData.AddPair(TJSONPair.Create('ID', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('Kontakte_ID').AsInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('salutation', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Anrede').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('name', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Vorname').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('surname', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Nachname').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('street_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Strasse_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('postalcode_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('PLZ_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('place_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Ort_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('phone_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Telefon_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('mobile_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Handy_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('mail_private', TJSONString.Create(dm_PCM.qry_Work.FieldByName('E_mail_Privat').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('birthday', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Geburtsdatum').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('gender', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Geschlecht').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('maritalstatus', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Familienstand').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('nationality', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Staatsangehoerigkeit').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('denomination', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Konfession').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('company', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Firma').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('street_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Strasse_Ges').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('postalcode_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('PLZ_Ges').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('place_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Ort_Ges').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('phone_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Telefon_Ges').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('mobile_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Handy_Ges').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('mail_business', TJSONString.Create(dm_PCM.qry_Work.FieldByName('E_mail_Ges').asString)));
      jaDetails.Add(joResponseJSONData);
      joResponseJSONData:= nil;
      dm_PCM.qry_work.Next;
    end;
    joResponseJSON.AddPair(TJSONPair.Create('Contacts', jaDetails));
  end
  else
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(1)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Datensätze vorhanden')));
  end;
  dm_PCM.qry_Work.Close;
  Result := joResponseJSON;
end;
// Kalender ermitteln
function GetKalender_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text := 'Select ID as Kalender_ID,EventType,Caption,Location, Message,'+
                                        'if(Kalendername = "Geburtstag",Cast(CONCAT_WS("-", YEAR(NOW()),Month(Start) ,DAY(Start)) AS DATETIME),START) AS Start,'+
                                        'if(Kalendername = "Geburtstag",Cast(CONCAT_WS("-", YEAR(NOW()),Month(Finish) ,DAY(Finish)) AS DATETIME),Finish) AS Finish,'+
                                        'CompleteDay,Reminder,'+
                                        'if(Kalendername = "Geburtstag",CAST(CONCAT_WS(" ",CONCAT_WS("-", YEAR(NOW()),Month(ReminderDate) ,DAY(ReminderDate)), CONCAT_WS("-", Hour(ReminderDate),Minute(ReminderDate) ,Second(ReminderDate))) AS DATETIME),ReminderDate) AS ReminderDate,'+
                                        'ReminderMinutesBeforeStart, Kalendername,RecurrenceInfo,ID_KalenderApp, wiederholung_text FROM manager_kalender ' +
                                        'WHERE (RecurrenceInfo IS NOT NULL OR START >= DATE_ADD(now(), INTERVAL -30 DAY)) AND ID_Benutzer = :ID and bearbeitetam is null' ;
  dm_PCM.qry_Work.ParamByName('ID').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Kalender lesen für Benutzer ' + AID_Benutzer + ', Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
  if dm_PCM.qry_Work.RecordCount > 0 then
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
    if not Assigned(jaDetails) then
      jaDetails := TJSONArray.Create;
    while not dm_PCM.qry_work.eof do
    begin
      if not Assigned(joResponseJSONData) then
        joResponseJSONData := TJSONObject.Create;
      joResponseJSONData.AddPair(TJSONPair.Create('ID', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('Kalender_ID').AsInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('eventType', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('EventType').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('caption', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Caption').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('location', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Location').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('message', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Message').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('start', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Start').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('finish', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Finish').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('completeDay', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('CompleteDay').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminder', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('Reminder').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderdate', TJSONString.Create(dm_PCM.qry_Work.FieldByName('reminderdate').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderbeforestart', TJSONString.Create(dm_PCM.qry_Work.FieldByName('ReminderMinutesBeforeStart').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('calendername', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Kalendername').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('ID_calenderapp', TJSONnumber.Create(dm_PCM.qry_Work.FieldByName('ID_KalenderApp').asInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('reccurrencetext', TJSONString.Create(dm_PCM.qry_Work.FieldByName('wiederholung_text').asString)));
      jaDetails.Add(joResponseJSONData);
      joResponseJSONData:= nil;
      dm_PCM.qry_work.Next;
    end;
    joResponseJSON.AddPair(TJSONPair.Create('Kontakte', jaDetails));
  end
  else
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(1)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Datensätze vorhanden')));
  end;
  dm_PCM.qry_Work.Close;
  Result := joResponseJSON;
end;
// Passwörter ermitteln
function GetPasswoerter_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text :=  'SELECT pw.id AS passwoerter_ID,pw.Bezeichnung,pw.user,pw.password,pw.link,pw.VPN_SharedSecret, ' +
                                         'pw.APP_IP,pw.APP_Port,pw.APP_Verschluesselung,pw.MAIL_Posteingangsserver,pw.MAIL_PosteingangsPort, ' +
                                         'pw.MAIL_PosteingangsVerschluesselung,pw.MAIL_Postausgangsserver,pw.MAIL_PostausgangsPort, ' +
                                         'pw.MAIL_PostausgangsVerschluesselung,pwt.Bezeichnung as pwtyp,pw.Wlan ' +
                                         'From manager_passwoerter pw ' +
                                         'LEFT OUTER JOIN manager_passwoerter_typ pwt ON pw.ID_Typ = pwt.ID ' +
                                         'Where ID_Benutzer = :ID';
  dm_PCM.qry_Work.ParamByName('ID').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Passwörter lesen, Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
  if dm_PCM.qry_Work.RecordCount > 0 then
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
    if not Assigned(jaDetails) then
      jaDetails := TJSONArray.Create;
    while not dm_PCM.qry_work.eof do
    begin
      if not Assigned(joResponseJSONData) then
        joResponseJSONData := TJSONObject.Create;
      joResponseJSONData.AddPair(TJSONPair.Create('ID', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('Kalender_ID').AsInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('eventType', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('EventType').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('caption', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Caption').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('location', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Location').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('message', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Message').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('start', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Start').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('finish', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Finish').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('completeDay', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('CompleteDay').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminder', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('Reminder').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderdate', TJSONString.Create(dm_PCM.qry_Work.FieldByName('reminderdate').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderbeforestart', TJSONString.Create(dm_PCM.qry_Work.FieldByName('ReminderMinutesBeforeStart').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('calendername', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Kalendername').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('ID_calenderapp', TJSONnumber.Create(dm_PCM.qry_Work.FieldByName('ID_KalenderApp').asInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('reccurrencetext', TJSONString.Create(dm_PCM.qry_Work.FieldByName('wiederholung_text').asString)));
      jaDetails.Add(joResponseJSONData);
      joResponseJSONData:= nil;
      dm_PCM.qry_work.Next;
    end;
    joResponseJSON.AddPair(TJSONPair.Create('Kontakte', jaDetails));
  end
  else
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(1)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Datensätze vorhanden')));
  end;
  dm_PCM.qry_Work.Close;
  Result := joResponseJSON;
end;
// Serials ermitteln
function GetSerials_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text := 'SELECT s.ID as Serials_ID,s.App AS Bezeichnung, sk.USER AS benutzer, ' +
                                        'sk.Serial AS serialkey, st.Bezeichnung as Typ ' +
                                        'FROM manager_serials S ' +
                                        'LEFT OUTER JOIN Manager_Serials_keys sk ON sk.ID_Serial = s.ID ' +
                                        'LEFT OUTER JOIN Manager_Serials_typ st ON st.ID = s.ID_TYp ' +
                                        'WHERE s.ID_Benutzer = :ID';
  dm_PCM.qry_Work.ParamByName('ID').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Serials lesen, Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
if dm_PCM.qry_Work.RecordCount > 0 then
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(false)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(0)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('')));
    if not Assigned(jaDetails) then
      jaDetails := TJSONArray.Create;
    while not dm_PCM.qry_work.eof do
    begin
      if not Assigned(joResponseJSONData) then
        joResponseJSONData := TJSONObject.Create;
      joResponseJSONData.AddPair(TJSONPair.Create('ID', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('Kalender_ID').AsInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('eventType', TJSONNumber.Create(dm_PCM.qry_Work.FieldByName('EventType').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('caption', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Caption').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('location', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Location').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('message', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Message').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('start', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Start').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('finish', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Finish').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('completeDay', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('CompleteDay').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminder', TJSONBool.Create(dm_PCM.qry_Work.FieldByName('Reminder').AsBoolean)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderdate', TJSONString.Create(dm_PCM.qry_Work.FieldByName('reminderdate').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('reminderbeforestart', TJSONString.Create(dm_PCM.qry_Work.FieldByName('ReminderMinutesBeforeStart').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('calendername', TJSONString.Create(dm_PCM.qry_Work.FieldByName('Kalendername').asString)));
      joResponseJSONData.AddPair(TJSONPair.Create('ID_calenderapp', TJSONnumber.Create(dm_PCM.qry_Work.FieldByName('ID_KalenderApp').asInteger)));
      joResponseJSONData.AddPair(TJSONPair.Create('reccurrencetext', TJSONString.Create(dm_PCM.qry_Work.FieldByName('wiederholung_text').asString)));
      jaDetails.Add(joResponseJSONData);
      joResponseJSONData:= nil;
      dm_PCM.qry_work.Next;
    end;
    joResponseJSON.AddPair(TJSONPair.Create('Kontakte', jaDetails));
  end
  else
  begin
    iCode:= 200;
    sMessage:= 'OK';
    joResponseJSON.AddPair(TJSONPair.Create('HasError',TJSONBool.Create(true)));
    joResponseJSON.AddPair(TJSONPair.Create('ErrorCode',TJSONNumber.Create(1)));
    joResponseJSON.AddPair(TJSONPair.Create('Errormessage',TJSONString.Create('Keine Datensätze vorhanden')));
  end;
  dm_PCM.qry_Work.Close;
  Result := joResponseJSON;
end;
// Ausgaben ermitteln
function GetAusgaben_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text :=  'SELECT id as Finanzen_Ausgaben_ID, Name,Beschreibung,Kontonummer,Bankleitzahl,Betrag,Fixkosten,Gueltig_Monat,Gueltig_Jahr,Verwendungszweck,FixBetrag ' +
                                         'FROM manager_finanzen_ausgaben Where ID_Benutzer = :ID';
  dm_PCM.qry_Work.ParamByName('ID').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Ausgaben lesen, Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
//  Result := dm_PCM.qry_Work;
end;
// Einnahmen ermitteln
function GetEinnahmen_Intern(AID_Benutzer: string): TJSONObject;
begin
  joResponseJSON:= nil;
  if not Assigned(joResponseJSON) then
    joResponseJSON := TJSONObject.Create;
  dm_PCM.qry_Work.SQL.Text :=  'SELECT ID AS Finanzen_Einnahmen_ID, Quelle, Betrag, Bezeichnung, FixBetrag ' +
                                         'FROM manager_finanzen_Einnahmen Where ID_Benutzer = :ID';
  dm_PCM.qry_Work.ParamByName('ID').AsInteger := StrToInt(AID_Benutzer);
  dm_PCM.qry_Work.Open;
  WriteLog(PCM_Logname,'Einnahmen lesen, Anzahl:' + IntToStr(dm_PCM.qry_Work.RecordCount),0);
//  Result := dm_PCM.qry_Work;
end;
end.
