object PCM_Service: TPCM_Service
  DisplayName = 'PCM-Service'
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  Height = 651
  Width = 955
  object FDManager: TFDManager
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <>
    Active = True
    Left = 328
    Top = 16
  end
  object ZipForge1: TZipForge
    ExtractCorruptedFiles = False
    CompressionLevel = clFastest
    CompressionMode = 1
    CurrentVersion = '6.94 '
    SpanningMode = smNone
    SpanningOptions.AdvancedNaming = False
    SpanningOptions.FirstVolumeSize = 0
    SpanningOptions.VolumeSize = vsAutoDetect
    SpanningOptions.CustomVolumeSize = 65536
    Options.FlushBuffers = True
    Options.OEMFileNames = True
    InMemory = False
    Zip64Mode = zmDisabled
    UnicodeFilenames = False
    EncryptionMethod = caPkzipClassic
    Left = 558
    Top = 16
  end
  object qryTermine: TFDQuery
    Connection = dm_PCM.con_PCM
    Left = 560
    Top = 80
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = Timer1Timer
    Left = 560
    Top = 144
  end
  object Timer2: TTimer
    Enabled = False
    OnTimer = Timer2Timer
    Left = 560
    Top = 208
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 200
    Top = 360
  end
  object FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink
    Left = 216
    Top = 416
  end
  object RESTClient1: TRESTClient
    Authenticator = HTTPBasicAuthenticator1
    Accept = 'application/json, text/plain; q=0.9, text/html;q=0.8,'
    AcceptCharset = 'utf-8, *;q=0.8'
    BaseURL = 'http://192.168.178.83:8081/PCM/api/v1/Refreshtoken'
    ContentType = 'application/x-www-form-urlencoded'
    Params = <>
    ConnectTimeout = 0
    ReadTimeout = 0
    SynchronizedEvents = False
    Left = 600
    Top = 440
  end
  object RESTRequest1: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = RESTClient1
    Method = rmPUT
    Params = <>
    Response = RESTResponse1
    ConnectTimeout = 0
    ReadTimeout = 0
    SynchronizedEvents = False
    Left = 472
    Top = 488
  end
  object RESTResponse1: TRESTResponse
    ContentType = 'application/json'
    Left = 624
    Top = 528
  end
  object HTTPBasicAuthenticator1: THTTPBasicAuthenticator
    Username = 'JHenske'
    Password = 'Jh2019+1'
    Left = 736
    Top = 416
  end
end
