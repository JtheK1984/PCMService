object PCM_Service: TPCM_Service
  DisplayName = 'PCM-Service'
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  Height = 977
  Width = 1433
  PixelsPerInch = 144
  object fdmgr_PCMService: TFDManager
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <>
    Active = True
    Left = 132
    Top = 72
  end
  object qry_Termine: TFDQuery
    Connection = dm_PCM.con_PCM
    Left = 132
    Top = 180
  end
  object tmr_Service: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmr_ServiceTimer
    Left = 312
    Top = 84
  end
  object tmr_BackupDatabase: TTimer
    Enabled = False
    OnTimer = tmr_BackupDatabaseTimer
    Left = 312
    Top = 192
  end
  object wtCsr_Mysql: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 132
    Top = 384
  end
  object physdvrLnk_Mysql: TFDPhysMySQLDriverLink
    Left = 132
    Top = 288
  end
end
