object dm_PCM: Tdm_PCM
  Height = 731
  Width = 1171
  object con_PCM: TFDConnection
    Params.Strings = (
      'Database=pcm'
      'User_Name=root'
      'Password=pcm'
      'Server='
      'Port=3307'
      'DriverID=MySQL')
    ResourceOptions.AssignedValues = [rvAutoReconnect]
    ResourceOptions.AutoReconnect = True    
	LoginPrompt = False
    BeforeConnect = con_PCMBeforeConnect
    Left = 56
    Top = 216
  end
  object qry_work: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 608
    Top = 448
  end
  object physdvrLnk_MySQL: TFDPhysMySQLDriverLink
    Left = 56
    Top = 359
  end
  object qry_work_Sub: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 656
    Top = 448
  end
  object qry_Service: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 56
    Top = 280
  end
  object rstreq_Push: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = rstClt_Push
    Method = rmPOST
    Params = <>
    Response = rstrsp_Push
    SynchronizedEvents = False
    Left = 56
    Top = 88
  end
  object rstClt_Push: TRESTClient
    Accept = 'application/json, text/plain; q=0.9, text/html;q=0.8,'
    AcceptCharset = 'utf-8, *;q=0.8'
    BaseURL = 'https://fcm.googleapis.com/fcm/send'
    ContentType = 'application/json'
    Params = <>
    SynchronizedEvents = False
    Left = 56
    Top = 32
  end
  object rstrsp_Push: TRESTResponse
    ContentType = 'text/html'
    Left = 56
    Top = 153
  end
  object qry_cal: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 512
    Top = 232
  end
  object qry_cal_sub: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 568
    Top = 232
  end
  object FDQuery1: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 608
    Top = 304
  end
  object FDQuery2: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 512
    Top = 296
  end
end
