unit RESTServer.Service.Version.vers1;

interface

uses
  WinApi.Windows,
  System.SysUtils, System.Classes, System.JSON, REST.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, DataSnap.DSProviderDataModuleAdapter,
  DataSnap.DSSession, Data.DBXPlatform,Data.DBXCommon,
  IdBaseComponent, IdSASL, IdSASLUserPass, IdSASL_CRAMBase, IdSASL_CRAM_MD5,
  IdHash, IdHashMessageDigest, IdHashSHA, IdHashCRC,Data.DB,
  RESTServer.Service.Records;
{$DEFINE PCMService}
type
  {$METHODINFO ON}
  v1 = class(TComponent)
  private
    { Private-Deklarationen }
    procedure ResultToJSONContent(const AJSONObject: TJSONObject);
  public
    { Public-Deklarationen }

    ////////////////////////////////////////////////////////////////////////////
    // PCM - RESTfunktionen                                                   //
    ////////////////////////////////////////////////////////////////////////////
    // Token erstellen
    [TRoleAuth('WebAPI_PCM')]
    function Createtoken: TJSONObject;
    // Token erneuern
    [TRoleAuth('WebAPI_PCM')]
    function AcceptRefreshtoken(const AJSONObject: TJSONObject): TJSONObject;
    // Token löschen
    [TRoleAuth('WebAPI_PCM')]
    function CancelDeletetoken: TJSONObject;
    // Backup erstellen
    [TRoleAuth('WebAPI_PCM')]
    function UpdateCreateBackup: TJSONObject;
    [TRoleAuth('WebAPI_PCM')]
    function UpdateGetKalenderConfig(const AJSONObject: TJSONObject): TJSONObject;

    ////////////////////////////////////////////////////////////////////////////
    // APP - RESTfunktionen                                                   //
    ////////////////////////////////////////////////////////////////////////////
    // Login ermitteln
    [TRoleAuth('WebAPI_PCM')]
    function GetLogin: TJSonObject;
    // kontakte ermitteln
    [TRoleAuth('WebAPI_PCM')]
    function UpdateGetContacts: TJSonObject;
    // Kalender ermitteln
    [TRoleAuth('WebAPI_PCM')]
    function UpdateGetKalender: TJSonObject;
  end;
  {$METHODINFO OFF}


implementation
uses
  PCM.Functions,
  PCM.Data,
  PCMService.API.Methods,
  PCMService.WebModules;

// Ergebnis in JSON umwandeln
procedure v1.ResultToJSONContent(const AJSONObject: TJSONObject);
var
  metaData: TDSInvocationMetadata;
begin
  metaData:= GetInvocationMetadata;
  metaData.ResponseContentType := 'application/json; charset=utf-8';
  metaData.ResponseContent := AJSONObject.ToJSON;
end;
////////////////////////////////////////////////////////////////////////////////
// PCM - RESTfunktionen                                                       //
////////////////////////////////////////////////////////////////////////////////
// Token erstellen
function v1.Createtoken: TJSONObject;
var
  metaData: TDSInvocationMetadata;
begin
  metaData := GetInvocationMetadata;
  Result := CreateToken_Intern;
  metaData.ResponseCode:= iCode;
  metaData.ResponseMessage:= sMessage;
  ResultToJSONContent(Result);
end;
// Token erneuern
function v1.AcceptRefreshtoken(const AJSONObject: TJSONObject): TJSONObject;
var
  metaData: TDSInvocationMetadata;
begin
  metaData := GetInvocationMetadata;
  Result := RefreshToken_Intern(AJSONObject);
  metaData.ResponseCode:= iCode;
  metaData.ResponseMessage:= sMessage;
  ResultToJSONContent(Result);
end;
// Token löschen
function v1.CancelDeletetoken: TJSONObject;
var
  metaData: TDSInvocationMetadata;
begin
 metaData := GetInvocationMetadata;
  if metaData.QueryParams.Count > 1 then
  begin
    Result := DeleteToken_Intern(StringReplace(metaData.QueryParams[0],'Token=','',[rfReplaceAll,rfIgnoreCase]),
    StrToInt(StringReplace(metaData.QueryParams[1],'Program=','',[rfReplaceAll,rfIgnoreCase])));
  end
  else
  begin
    Result := DeleteToken_Intern('',999);
  end;
  metaData.ResponseCode:= iCode;
  metaData.ResponseMessage:= sMessage;
  ResultToJSONContent(Result);
end;
// Backuperstellen
function v1.UpdateCreateBackup: TJSONObject;
var
  metaData: TDSInvocationMetadata;
begin
  metaData := GetInvocationMetadata;
  if metaData.QueryParams.Count > 1 then
  begin
    Result := CreateBackup_Intern(StringReplace(metaData.QueryParams[0],'Token=','',[rfReplaceAll,rfIgnoreCase]),
    StringReplace(metaData.QueryParams[1],'Path=','',[rfReplaceAll,rfIgnoreCase]));
  end
  else
  begin
    metaData.ResponseCode:= 400;
    Result := CreateBackup_Intern('','');
  end;
  ResultToJSONContent(Result);
end;
// Kalenderkonfiguration ermitteln
function v1.UpdateGetKalenderConfig(const AJSONObject: TJSONObject): TJSONObject;
begin
  Result := GetKalenderConfig_Intern(AJSONObject);
  ResultToJSONContent(Result);
end;
////////////////////////////////////////////////////////////////////////////////
// APP - RESTfunktionen                                                       //
////////////////////////////////////////////////////////////////////////////////
function v1.GetLogin: TJSonObject;
begin
  Result:= GetLogin_Intern;
  ResultToJSONContent(Result);
end;
function v1.UpdateGetContacts: TJSonObject;
var
  metaData: TDSInvocationMetadata;
begin
  metaData := GetInvocationMetadata;
  if metaData.QueryParams.Count = 1 then
  begin
    Result := GetKontakte_Intern(StringReplace(metaData.QueryParams[0],'ID_User=','',[rfReplaceAll,rfIgnoreCase]));
  end
  else
  begin
    metaData.ResponseCode:= 400;
    Result := GetKontakte_Intern('');
  end;
  ResultToJSONContent(Result);
end;
function v1.UpdateGetKalender: TJSonObject;
var
  metaData: TDSInvocationMetadata;
begin
  metaData := GetInvocationMetadata;
  if metaData.QueryParams.Count = 1 then
  begin
    Result := GetKalender_Intern(StringReplace(metaData.QueryParams[0],'ID_User=','',[rfReplaceAll,rfIgnoreCase]));
  end
  else
  begin
    metaData.ResponseCode:= 400;
    Result := GetKalender_Intern('');
  end;
  ResultToJSONContent(Result);
end;
end.

