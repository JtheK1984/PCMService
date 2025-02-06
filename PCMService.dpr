program PCMService;

uses
  Windows,
  PCM.Main in 'PCM.Main.pas' {PCM_Service: TService},
  PCM.Data in 'PCM.Data.pas' {dm_PCM: TDataModule},
  Vcl.SvcMgr;

{$R *.RES}

{$SetPEOptFlags IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE}
{$SetPEFlags IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP or IMAGE_FILE_NET_RUN_FROM_SWAP or IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TPCM_Service, PCM_Service);
  Application.CreateForm(Tdm_PCM, dm_PCM);
  Application.Run;
end.

