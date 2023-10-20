program PCMService;

uses
  Vcl.SvcMgr,
  PCM.Main in 'PCM.Main.pas' {PCM_Service: TService},
  PCM.Data in 'PCM.Data.pas' {dm_PCM: TDataModule};

{$R *.RES}

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TPCM_Service, PCM_Service);
  Application.CreateForm(Tdm_PCM, dm_PCM);
  Application.Run;
end.

