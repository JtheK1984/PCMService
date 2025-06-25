object dm_PCM: Tdm_PCM
  Height = 1097
  Width = 1757
  PixelsPerInch = 144
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
    Left = 84
    Top = 324
  end
  object qry_work: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 912
    Top = 672
  end
  object physdvrLnk_MySQL: TFDPhysMySQLDriverLink
    Left = 84
    Top = 539
  end
  object qry_work_Sub: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 984
    Top = 672
  end
  object qry_Service: TFDQuery
    Connection = con_PCM
    SQL.Strings = (
      '')
    Left = 84
    Top = 420
  end
  object rstreq_Push: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = rstClt_Push
    Method = rmPOST
    Params = <>
    Response = rstrsp_Push
    SynchronizedEvents = False
    Left = 84
    Top = 132
  end
  object rstClt_Push: TRESTClient
    Accept = 'application/json, text/plain; q=0.9, text/html;q=0.8,'
    AcceptCharset = 'utf-8, *;q=0.8'
    BaseURL = 'https://fcm.googleapis.com/fcm/send'
    ContentType = 'application/json'
    Params = <>
    SynchronizedEvents = False
    Left = 84
    Top = 48
  end
  object rstrsp_Push: TRESTResponse
    ContentType = 'text/html'
    Left = 84
    Top = 230
  end
  object qry_cal: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 768
    Top = 348
  end
  object qry_cal_sub: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 852
    Top = 348
  end
  object FDQuery1: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 912
    Top = 456
  end
  object FDQuery2: TFDQuery
    Connection = con_PCM
    FetchOptions.AssignedValues = [evMode, evRecordCountMode]
    FetchOptions.Mode = fmAll
    FetchOptions.RecordCountMode = cmTotal
    SQL.Strings = (
      '')
    Left = 768
    Top = 444
  end
end
