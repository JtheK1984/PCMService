object PCM_Service: TPCM_Service
  DisplayName = 'PCM-Service'
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  Height = 651
  Width = 955
  object fdmgr_PCMService: TFDManager
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <>
    Active = True
    Left = 88
    Top = 48
  end
  object qry_Termine: TFDQuery
    Connection = dm_PCM.con_PCM
    Left = 88
    Top = 120
  end
  object tmr_Service: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmr_ServiceTimer
    Left = 208
    Top = 56
  end
  object tmr_BackupDatabase: TTimer
    Enabled = False
    OnTimer = tmr_BackupDatabaseTimer
    Left = 208
    Top = 128
  end
  object wtCsr_Mysql: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 88
    Top = 256
  end
  object physdvrLnk_Mysql: TFDPhysMySQLDriverLink
    Left = 88
    Top = 192
  end
end
