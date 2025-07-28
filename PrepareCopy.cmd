echo "Kopiere Datei ins Setupverzeichnis 32-Bit"
copy /y /v Win32\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService"
echo "Kopiere Datei ins Setupverzeichnis 64-Bit"
copy /y /v Win64\Release\PCMService.exe "e:\Inno\Setupfiles\Programme\PCMService_x64"

echo "Kopiere Doku ins Setupverzeichnis"
copy /y /v PCMService.docx "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v PCMService.pdf "e:\Inno\Setupfiles\Programme\PCMService"
copy /y /v PCMService.htm "e:\Inno\Setupfiles\Programme\PCMService"
