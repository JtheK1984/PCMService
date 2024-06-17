echo "Kopiere Datei ins Setupverzeichnis"
copy /y /v Win32\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v Win64\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService_x64"

copy /y /v Win64\Release\PCMService.DE "e:\Inno\Setupfiles\Programme\PCMService_x64"
copy /y /v Win64\Release\PCMService.EN "e:\Inno\Setupfiles\Programme\PCMService_x64"

copy /y /v PCMService.docx "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v PCMService.pdf "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v PCMService.htm "e:\Inno\Setupfiles\Programme\PCMService"