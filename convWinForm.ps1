function Convert-WinForm([string]$Source, [string]$Destination)
{
	#$Source = "C:\Users\Zanzo\source\repos\WinForms2Powershell-GUI\Form1.Designer.cs"
	#$Destination = "D:\GitHub\SongsterrGPDownloader\gui\"
	Convert-Form -Path $Source -Destination $Destination -Encoding ascii -force
}

Convert-WinForm -Source "C:\Users\Zanzo\source\repos\SongsterrGPDownloader-GUI\frmMain.Designer.cs" -Destination "D:\GitHub\SongsterrGPDownloader\gui\"