call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
echo "Build erstellen"
msbuild E:/Projekte/Windows/PCMService/PCMService.dproj /t:Clean;Build;CompressWin32 /p:config=Release /p:platform=Win32
msbuild E:/Projekte/Windows/PCMService/PCMService.dproj /t:Clean;Build;CompressWin64 /p:config=Release /p:platform=Win64

echo "Kopiere Datei ins Setupverzeichnis 32-Bit"
copy /y /v E:\Projekte\Windows\PCMService\Win32\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v E:\Projekte\Windows\PCMService\Win32\Release\PCMService.DE "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v E:\Projekte\Windows\PCMService\Win32\Release\PCMService.EN "e:\Inno\Setupfiles\Programme\PCMService"

echo "Kopiere Datei ins Setupverzeichnis 64-Bit"
copy /y /v E:\Projekte\Windows\PCMService\Win64\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService_x64"
copy /y /v E:\Projekte\Windows\PCMService\Win64\Release\PCMService.DE "e:\Inno\Setupfiles\Programme\PCMService_x64"
copy /y /v E:\Projekte\Windows\PCMService\Win64\Release\PCMService.EN "e:\Inno\Setupfiles\Programme\PCMService_x64"

echo "Kopiere Doku ins Setupverzeichnis"
copy /y /v E:\Projekte\Windows\PCMService\PCMService.docx "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v E:\Projekte\Windows\PCMService\PCMService.pdf "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v E:\Projekte\Windows\PCMService\PCMService.htm "e:\Inno\Setupfiles\Programme\PCMService"
