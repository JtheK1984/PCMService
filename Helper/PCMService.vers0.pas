unit PCMService.vers0;

interface

uses
  System.SysUtils, System.Classes, System.JSON;

type
{$METHODINFO ON}
  v0 = class(TComponent)
  private

    { Private-Deklarationen }

  public
    { Public-Deklarationen }
//    function auth(): TJSONObject;
//    function updateauthprg(const AJSONObject: TJSONObject): TJSONObject;
  end;
{$METHODINFO OFF}

implementation


uses
  System.StrUtils,
  Datasnap.DSSession,
//  ´RESTServer.Service.Helper, RESTServer.Service.Records,
  PCM.Data;

//function v0.auth(): TJSONObject;
//begin
//  Result := CallRESTAPI(Auth_Intern);
//end;

//function v0.updateauthprg(const AJSONObject: TJSONObject): TJSONObject;
//begin
//  Result := CallRESTAPI(AuthPrg_Intern, AJSONObject);
//end;



end.
