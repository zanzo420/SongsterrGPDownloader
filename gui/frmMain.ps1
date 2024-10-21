# Loading external assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$frmMain = New-Object System.Windows.Forms.Form

$grpSearch = New-Object System.Windows.Forms.GroupBox
$grpResults = New-Object System.Windows.Forms.GroupBox
$txtArtist = New-Object System.Windows.Forms.TextBox
$lblArtist = New-Object System.Windows.Forms.Label
$lblTitle = New-Object System.Windows.Forms.Label
$txtTitle = New-Object System.Windows.Forms.TextBox
$btnSearch = New-Object System.Windows.Forms.Button
$lstArtistName = New-Object System.Windows.Forms.ListBox
$btnDownload = New-Object System.Windows.Forms.Button
$lstArtistID = New-Object System.Windows.Forms.ListBox
$lstSongTitle = New-Object System.Windows.Forms.ListBox
$lstSongID = New-Object System.Windows.Forms.ListBox
$lblArtistResults = New-Object System.Windows.Forms.Label
$lblArtistIDResults = New-Object System.Windows.Forms.Label
$lblSongIDResults = New-Object System.Windows.Forms.Label
$lblSongTitleResults = New-Object System.Windows.Forms.Label
$lstURL = New-Object System.Windows.Forms.ListBox
$lblUrlResults = New-Object System.Windows.Forms.Label

function Search-Songsterr([string]$pattern, [int]$startIndex = 0)
{
    $escString = [URI]::EscapeUriString($pattern)
    $data = ConvertTo-Json -InputObject (Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)&from=$($startIndex)") -depth 10 
    $saveData = $data
    $saveData | out-file "$($pattern)_searchResults.json"
    return ConvertFrom-Json -InputObject $data -Depth 10
}

function DownloadTabBySongID([string]$SongID)
{
    # Define the base URL for Songsterr API
    $baseUrl = "https://www.songsterr.com/api/meta"
    $baseDLUrl = "https://gp.songsterr.com"

    # Retrieve the latest revision metadata
    $revisionUrl = "$baseUrl/$SongID/revisions"
    $revisionMetadata = Invoke-RestMethod -Uri $revisionUrl

    # Extract the Guitar Pro download URL
    $downloadUrl = $revisionMetadata[0].source
    # Extract the filename from the URL
    $oldFilename = $downloadUrl.Replace("$($baseDLUrl)/", "")

    # Extract the artist and title from the metadata
    $artist = $revisionMetadata[0].artist
    $title = $revisionMetadata[0].title

    # Define the destination file path
    $destinationPath = "$($savedir)\SongsterrGPDownloader\$($oldFilename)"
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
    # Define the new file name
    $newFileName = "$($artist) - $($title)$($oldFilename.Replace("export",''))"
    # Rename the file
    Rename-Item -Path $destinationPath -NewName "$($newFileName)"

    Write-Host "Guitar Pro tab downloaded and renamed to " -NoNewLine; write-Host $newFileName -ForegroundColor Green
}

function ClearLists()
{
	$lstArtistName.Items.Clear()
	$lstArtistID.Items.Clear()
	$lstSongTitle.Items.Clear()
	$lstSongID.Items.Clear()
	$lstURL.Items.Clear()
}

#
# grpSearch
#
$grpSearch.Controls.Add($btnSearch)
$grpSearch.Controls.Add($lblTitle)
$grpSearch.Controls.Add($txtTitle)
$grpSearch.Controls.Add($lblArtist)
$grpSearch.Controls.Add($txtArtist)
$grpSearch.Location = New-Object System.Drawing.Point(8, 5)
$grpSearch.Name = "grpSearch"
$grpSearch.Size = New-Object System.Drawing.Size(741, 66)
$grpSearch.TabIndex = 0
$grpSearch.TabStop = $false
$grpSearch.Text = "Search"
#
# grpResults
#
$grpResults.Controls.Add($lblUrlResults)
$grpResults.Controls.Add($lstURL)
$grpResults.Controls.Add($lblSongIDResults)
$grpResults.Controls.Add($lblSongTitleResults)
$grpResults.Controls.Add($lblArtistIDResults)
$grpResults.Controls.Add($lblArtistResults)
$grpResults.Controls.Add($lstSongID)
$grpResults.Controls.Add($lstSongTitle)
$grpResults.Controls.Add($lstArtistID)
$grpResults.Controls.Add($lstArtistName)
$grpResults.Location = New-Object System.Drawing.Point(8, 77)
$grpResults.Name = "grpResults"
$grpResults.Size = New-Object System.Drawing.Size(741, 276)
$grpResults.TabIndex = 1
$grpResults.TabStop = $false
$grpResults.Text = "Results"
#
# txtArtist
#
$txtArtist.Location = New-Object System.Drawing.Point(9, 32)
$txtArtist.Name = "txtArtist"
$txtArtist.Size = New-Object System.Drawing.Size(278, 20)
$txtArtist.TabIndex = 0
#
# lblArtist
#
$lblArtist.AutoSize = $true
$lblArtist.BackColor = [System.Drawing.Color]::Transparent
$lblArtist.Location = New-Object System.Drawing.Point(6, 16)
$lblArtist.Name = "lblArtist"
$lblArtist.Size = New-Object System.Drawing.Size(33, 13)
$lblArtist.TabIndex = 1
$lblArtist.Text = "Artist:"
#
# lblTitle
#
$lblTitle.AutoSize = $true
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$lblTitle.Location = New-Object System.Drawing.Point(297, 16)
$lblTitle.Name = "lblTitle"
$lblTitle.Size = New-Object System.Drawing.Size(30, 13)
$lblTitle.TabIndex = 3
$lblTitle.Text = "Title:"
#
# txtTitle
#
$txtTitle.Location = New-Object System.Drawing.Point(300, 32)
$txtTitle.Name = "txtTitle"
$txtTitle.Size = New-Object System.Drawing.Size(281, 20)
$txtTitle.TabIndex = 2
#
# btnSearch
#
$btnSearch.Location = New-Object System.Drawing.Point(587, 16)
$btnSearch.Name = "btnSearch"
$btnSearch.Size = New-Object System.Drawing.Size(148, 44)
$btnSearch.TabIndex = 4
$btnSearch.Text = "Search"
$btnSearch.UseVisualStyleBackColor = $true

$btnSearch.Add_Click({
    $searchResults = Search-Songsterr -pattern "$($txtArtist.Text) - $($txtTitle.Text)"
	ClearLists
	foreach($result in $searchResults)
	{
		$lstArtistName.Items.Add("$($result.artist)")
		$lstArtistID.Items.Add("$($result.artistid)")
		$lstSongTitle.Items.Add("$($result.title)")
		$lstSongID.Items.Add("$($result.songid)")
		#$lstURL.Items.Add("$($result.url)")
	}
})

#
# lstArtistName
#
$lstArtistName.FormattingEnabled = $true
$lstArtistName.Location = New-Object System.Drawing.Point(9, 32)
$lstArtistName.Name = "lstArtistName"
$lstArtistName.Size = New-Object System.Drawing.Size(142, 238)
$lstArtistName.TabIndex = 0
#
# btnDownload
#
$btnDownload.Location = New-Object System.Drawing.Point(651, 359)
$btnDownload.Name = "btnDownload"
$btnDownload.Size = New-Object System.Drawing.Size(98, 27)
$btnDownload.TabIndex = 2
$btnDownload.Text = "Download"
$btnDownload.UseVisualStyleBackColor = $true
#
# lstArtistID
#
$lstArtistID.FormattingEnabled = $true
$lstArtistID.Location = New-Object System.Drawing.Point(157, 32)
$lstArtistID.Name = "lstArtistID"
$lstArtistID.Size = New-Object System.Drawing.Size(65, 238)
$lstArtistID.TabIndex = 1
#
# lstSongTitle
#
$lstSongTitle.FormattingEnabled = $true
$lstSongTitle.Location = New-Object System.Drawing.Point(228, 32)
$lstSongTitle.Name = "lstSongTitle"
$lstSongTitle.Size = New-Object System.Drawing.Size(147, 238)
$lstSongTitle.TabIndex = 2
#
# lstSongID
#
$lstSongID.FormattingEnabled = $true
$lstSongID.Location = New-Object System.Drawing.Point(381, 32)
$lstSongID.Name = "lstSongID"
$lstSongID.Size = New-Object System.Drawing.Size(65, 238)
$lstSongID.TabIndex = 3
#
# lblArtistResults
#
$lblArtistResults.AutoSize = $true
$lblArtistResults.BackColor = [System.Drawing.Color]::Transparent
$lblArtistResults.Location = New-Object System.Drawing.Point(6, 17)
$lblArtistResults.Name = "lblArtistResults"
$lblArtistResults.Size = New-Object System.Drawing.Size(64, 13)
$lblArtistResults.TabIndex = 4
$lblArtistResults.Text = "Artist Name:"
#
# lblArtistIDResults
#
$lblArtistIDResults.AutoSize = $true
$lblArtistIDResults.BackColor = [System.Drawing.Color]::Transparent
$lblArtistIDResults.Location = New-Object System.Drawing.Point(154, 17)
$lblArtistIDResults.Name = "lblArtistIDResults"
$lblArtistIDResults.Size = New-Object System.Drawing.Size(47, 13)
$lblArtistIDResults.TabIndex = 5
$lblArtistIDResults.Text = "Artist ID:"
#
# lblSongIDResults
#
$lblSongIDResults.AutoSize = $true
$lblSongIDResults.BackColor = [System.Drawing.Color]::Transparent
$lblSongIDResults.Location = New-Object System.Drawing.Point(378, 17)
$lblSongIDResults.Name = "lblSongIDResults"
$lblSongIDResults.Size = New-Object System.Drawing.Size(49, 13)
$lblSongIDResults.TabIndex = 7
$lblSongIDResults.Text = "Song ID:"
#
# lblSongTitleResults
#
$lblSongTitleResults.AutoSize = $true
$lblSongTitleResults.BackColor = [System.Drawing.Color]::Transparent
$lblSongTitleResults.Location = New-Object System.Drawing.Point(225, 17)
$lblSongTitleResults.Name = "lblSongTitleResults"
$lblSongTitleResults.Size = New-Object System.Drawing.Size(58, 13)
$lblSongTitleResults.TabIndex = 6
$lblSongTitleResults.Text = "Song Title:"
#
# lstURL
#
$lstURL.FormattingEnabled = $true
$lstURL.Location = New-Object System.Drawing.Point(522, 32)
$lstURL.Name = "lstURL"
$lstURL.Size = New-Object System.Drawing.Size(213, 238)
$lstURL.TabIndex = 8
#
# lblUrlResults
#
$lblUrlResults.AutoSize = $true
$lblUrlResults.BackColor = [System.Drawing.Color]::Transparent
$lblUrlResults.Location = New-Object System.Drawing.Point(519, 16)
$lblUrlResults.Name = "lblUrlResults"
$lblUrlResults.Size = New-Object System.Drawing.Size(32, 13)
$lblUrlResults.TabIndex = 9
$lblUrlResults.Text = "URL:"
#
# frmMain
#
$frmMain.ClientSize = New-Object System.Drawing.Size(761, 398)
$frmMain.Controls.Add($btnDownload)
$frmMain.Controls.Add($grpResults)
$frmMain.Controls.Add($grpSearch)
$frmMain.Name = "frmMain"
$frmMain.Text = "Songsterr GP Downloader"

# Show the form
$frmMain.ShowDialog()
