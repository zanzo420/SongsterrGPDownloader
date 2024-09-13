#### TO-DO: ######################################################################
## - Output list of generated urls to .txt file                                 ##
## - Scrape GPT download link from each URL in .txt file                        ##
## - Loop each scraped GPT download link and download each file.                ##
## - Rename all files downloaded using their associated artist name/song title. ##
##################################################################################
Import-Module -Name ImportExcel
###### GLOBAL VARIABLES #######
$savedir = "D:\.GuitarPro"
#$SpotifyAPIUrl = "https://api.spotify.com/"



#########################################################
# Get Songsterr GuitarPro Tabs using Songsterr JSON API #
#########################################################
function Get-SongsterrTabs($startIndex = 0)
{
    $prefix = "http://www.songsterr.com/a/wsa/"
    $apiURL = "https://www.songsterr.com/api/songs?pattern=&size=250&from="
    $songLinks = @()
    
    #[int]$pageCount = [int]$(gc -Path "H:\.midi\PageCount.txt")
    $pageMax = 21
    $songIndex = $startIndex
    
    for($i=0; $i -lt $pageMax; $i++)
    {
        $webAPIDataPage = Invoke-RestMethod -Uri "$($apiURL)$($songIndex)"
        #$songIndex++
        
        #loop through all songs in the JSON...
        $indx = 0
        foreach($songJSON in $webAPIDataPage)
        {
            $songLinks += "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)"
            write-host "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)" | out-file ".\songsterr_LINKS.txt" -Append -Force
            $indx++
        }##END## SongJSON Loop ###############################################

        #add links from current API page to file...
        $songLinks | out-file ".\SongLinks\SongLinks-pg$($i+1).txt" -Force -Append
        $songIndex = $startIndex+$i*250
        write-host "[PAGE: $($i) | SONGS: $($indx)]" -ForegroundColor Green -NoNewline
        write-host " SongIndex = $($songIndex)" -ForegroundColor Red
    }##END## API PAGE LOOP ################################################

    return $songLinks | out-file ".\SongLinks\SongLinks-FULL.txt" -Force -Append
    #$pageCount += $songIndex | out-file H:\.midi\PageCount.txt -Force
}
#function that gets json data from songsterr api and saves it to a file...
function Search-Songsterr($pattern, $instrument = "any", $startIndex = 0)
{
    $data = ConvertTo-Json -InputObject (Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&inst=$($instrument)&pattern=$($pattern)&from=$($startIndex)") -depth 10 
    $saveData = $data
    $saveData | out-file "$($pattern)_searchResults.json"
    return ConvertFrom-Json -InputObject $data -Depth 10
}

function Search-SongsterrTabs($pattern, $instrument = "any", $startIndex = 0)
{
    $prefix = "http://www.songsterr.com/a/wsa/"
    $apiURL = "https://www.songsterr.com/api/songs?size=250&inst=$($instrument)&pattern=$($pattern)&from="
    $songLinks = @()
    $results = ''
    
    #[int]$pageCount = [int]$(gc -Path "H:\.midi\PageCount.txt")
    $pageMax = 21
    $songIndex = $startIndex
    $sIndx = 0
    for($i=0; $i -lt $pageMax; $i++)
    {
        $webAPIDataPage = Invoke-RestMethod -Uri "$($apiURL)$($songIndex)" -UseBasicParsing
        $results = ConvertFrom-Json -InputObject (ConvertTo-Json($webAPIDataPage) -Depth 10) -Depth 10 | out-file ".\SearchResults_$($pattern)-pg$($i).json" -Force
        write-host $results
        #loop through all songs in the JSON data...
        $indx = 0
        foreach($songJSON in $webAPIDataPage)
        {
            $songLinks += "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)"
            write-host "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)" | out-file ".\songsterr_LINKS.txt" -Append -Force
            $saveLinks = $songLinks
            $saveLinks | out-file ".\SearchResults-pg$($i).txt" -Force -Append
            $indx++
        }##END## SongJSON Loop ###############################################

        #add links from current API page to file...
        $songLinks | out-file ".\SearchResults_$($pattern)-pg$($i).txt" -Force
        $songIndex = $startIndex+$i*250
        write-host "[PAGE: $($i) | SONGS: $($indx)]" -ForegroundColor Green -NoNewline
        write-host " SongIndex = $($songIndex)" -ForegroundColor Red
        $sIndx++
    }##END## API PAGE LOOP ################################################

    $songLinks | out-file ".\SearchResults_$($pattern)-FULL.txt" -Force -Append
    #$pageCount += $songIndex | out-file H:\.midi\PageCount.txt -Force
    return ConvertTo-Json -InputObject (invoke-restmethod -uri "https://www.songsterr.com/api/songs?size=250&from=0&inst=drum&pattern=$($pattern)") -depth 10 | out-file TEMPFILE.json
}



########################################################
## Search For Tabs By Artist Using Songsterr JSON API ##
########################################################
# Search for Songsterr Tabs by Artist Name (or Song Title)...
function Get-SongsterrTabsByArtist($artistName)
{
    $results = @()

    if($artistName -eq "")
    {
        $SearchString = read-host "Enter an Artist and/or Song to search for..."
    }else{
        $SearchString = $artistName
    }
    $escString = [URI]::EscapeUriString($SearchString)

    ## Using Invoke-RestMethod
    $webAPIData = Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)"
    $webJSON = ConvertFrom-Json -InputObject $webAPIData -Depth 10
    write-host $webJSON
    ## Using Invoke-WebRequest
    #$webAPIData = ConvertFrom-JSON (Invoke-WebRequest -uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)")

    ## The download information is stored in the "assets" section of the data
    $songs = $webJSON.assets #$webAPIData
    #$webAPIData | Get-Member

    # Generate a http URL for each song...
    foreach($song in $webAPIData)
    {
        write-host "http://www.songsterr.com/a/wsa/" -NoNewline
        write-host "$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)" | out-file "SearchResults_$($artistName).txt" -Force
        $results += "http://www.songsterr.com/a/wsa/$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)"
    }
    $results | out-file ".\SearchResults\$($SearchString).txt" -Force
    
    return $results
}
# Get Songsterr tabs by Artist from a .txt list of artists
function GetSongsterrTabsByArtistList($artistlist)
{
    $list = gc $artistlist
    foreach($a in $list)
    {
        Get-SongsterrTabsByArtist $a
    }
}

##################################################################
## Combine All Search Results in the .\SearchResults\ Directory ##
################################################################## 
function CombineAllSearchResults()
{
    
    cd .\SearchResults
    $results = @()
    $getSearchResults = gci .\* -Include *.txt
    foreach($r in $getSearchResults)
    {
        $SearchData = gc $r
        write-host $SearchData | out-file .\SearchData.txt -Append -Force
        $results += $SearchData 
    }
    cd ..
    $results | out-file .\CombinedSearchResults.txt -Force
    
    return $results
}
function GetCombinedSearchResultsTabData()
{
    write-host "Getting SongID's from CombinedSearchResults.txt..."
    pause
    GetSongIdsFromUrls CombinedSearchResults.txt
    write-host "Getting DownloadURL's from SongID's..."
    pause
    GetSongsterrDownloadURLs SongIdsFromUrls.txt
    #write-host "Downloading all Tabs from DownloadURLs.txt..."
    #DownloadSongsterrTabs
    write-host "COMPLETE!"
}

function Get-TabAndDownload {
    param (
        [int]$TabID
    )

    # Define the base URL for Songsterr API
    $baseUrl = "https://www.songsterr.com/api/meta"
    $baseDLUrl = "https://gp.songsterr.com"

    # Retrieve the latest revision metadata
    $revisionUrl = "$baseUrl/$TabID/revisions"
    $revisionMetadata = Invoke-RestMethod -Uri $revisionUrl

    # Extract the Guitar Pro download URL
    $downloadUrl = $revisionMetadata[0].source

    # Extract the filename from the URL
    $oldFilename = $downloadUrl.Replace("$($baseDLUrl)/", "")

    # Extract the artist and title from the metadata
    $artist = $revisionMetadata[0].artist
    $title = $revisionMetadata[0].title

    # Extract the revision ID
    $revId = $revisionMetadata[0].revisionId

    # Define the destination file path
    $destinationPath = ".\Files\$($oldFilename)"

    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath

    # Define the new file name
    $newFileName = "$($artist) - $($title)$($oldFilename.ToString().Replace("export",''))"

    # Rename the file
    Rename-Item -Path $destinationPath -NewName "$($newFileName)"

    write-host "$($artist) - $($title)" -ForegroundColor cyan -NoNewline
    Write-Host " Guitar Pro tab downloaded and renamed to " -NoNewLine
    write-Host $newFileName -ForegroundColor Green
}

# Example usage
#Get-TabAndDownload -TabID "534532"


$cookie = 'OrigRef=d3d3Lmdvb2dsZS5jb20=; _ga=GA1.2.563324618.1641686257; G_ENABLED_IDPS=google; __gads=ID=b5de266b76d30fa8:T=1641686257:S=ALNI_MZxgEGqVWRkMMew-r_CunkutRPrQg; SongsterrL=b0b18683873fd827048dff32450b36910f6bba9e8ef30a9f; cto_bundle=uLgR3V94aUdUbzhmQVpDeW1nR3NlbHlReThHJTJCNlBGSUNnZklXeVpQREluamU3RmZTR21vZEtTVXdmJTJCOEtIZnVIbU5iZiUyRndCeFFvbTEyS3NES21EOUJ5N2ZHJTJGJTJGSmI0MUdUTGNGbEpsTm94RDE0TnF4V2lBRXRjbUx2NHZTQ2N1R0pzclNZb1VrMFpHUmglMkZTd0s4cXN3U2dNSkElM0QlM0Q; ScrShwn-svws=true; LastRef=d3d3Lmdvb2dsZS5jb20=; EE_STORAGE=["video_walkthrough","comments_removal"]; lastSeenTrack=/a/wsa/falling-in-reverse-wait-and-see-half-solo-tab-s398766; experiments={"aa":"on","sound_v4":"off","comments_removal":"on","new_plus_banner":"off"}; _gid=GA1.2.1968037562.1656242890; amp_9121af=XrOZ72J_mkX5E6aGJkftn4.MjMyMDYzMA==..1g6gt3qtj.1g6gt93ho.2p.2p.5i; SongsterrT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIyMzIwNjMwIiwiZW1haWwiOiJ6Q2xvbmVIZXJvQGdtYWlsLmNvbSIsIm5hbWUiOiJ6Q2xvbmVIZXJvIiwicGxhbiI6InBsdXMiLCJzdWJzY3JpcHRpb24iOnsic3RhdHVzIjoiYWN0aXZlIiwidHlwZSI6ImJyYWludHJlZSIsInN0YXJ0RGF0ZSI6IjIwMjItMDUtMDhUMDQ6NTE6MzQuMDAwWiIsImVuZERhdGUiOm51bGwsImNhbmNlbGxhdGlvbkRhdGUiOm51bGx9LCJzcmFfbGljZW5zZSI6Im5vbmUiLCJnb29nbGUiOiIxMDExNDgyNDE3ODYwODgwNDQxMzQiLCJpYXQiOjE2NTYyNzc2NjQsImlkIjoiMjMyMDYzMCJ9.e-cSj5xaosVcet1kNciKL2cxmiOu0lGlREz3HFNLhao'
#$dlPrefix = 'https://d12drcwhcokzqv.cloudfront.net/'
$dlPrefix = 'https://gp.songsterr.com/'
$SongIDs = gc -Path D:\SongIDs.txt
$data = @()
$fileData = @()


###################################################
#region Get all song data from a songsterr SongID #
###################################################
function GetSongsterrDownloadData($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    
    $RevisionId = $R[0].revisionId | out-host
    $Title = $R[0].title #| out-host
    $Artist = $R[0].artist #| out-host

    $DownloadURL = $R[0].source | out-host
    $fExt = $R[0].source.Split(".")
    $fileExt = $fExt[$fExt.Length-1] #| out-host
    $nFilename = "$($R[0].artist) - $($R[0].title).$($fileExt)" | out-host

    $data += "$($songid)`n"
    $data += "$($R[0].source)`n"
    $data += "$($R[0].revisionId)`n"
    $data += "$($R[0].title)`n"
    $data += "$($R[0].artist)`n"
    $data += "$($nFilename)`n"

    return $data | out-file .\songsterrData.txt -Append -Force
}
#endregion


#################################################
#region GET SONGSTERR DOWNLOAD DATA FROM SONGID #
#################################################
# Get a Download URL from a Songsterr SongID...
function GetSongsterrDownloadURL($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getDownloadURL = $R[0].source #| out-host
    
    return $($R[0].source).ToString()
}
function GetSongsterrRevisionID($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getRevisionID = $R[0].revisionId #| out-host
    
    return $($R[0].revisionId).ToString()
}
function GetSongsterrTitle($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getTitle = $R[0].title #| out-host
    
    return $($R[0].title).ToString()
}
function GetSongsterrArtist($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getArtist = $R[0].artist #| out-host
    
    return $($R[0].artist).ToString()
}
function GetSongsterrTracks($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getTracks = $R[0].tracks #| out-host
    
    return $($R[0].tracks).ToString()
}
# Get the Artist and SongTitle from a Songsterr SongID...
function GetSongsterrArtistAndTitle($songid)
{
    $dlUrlPrefix = 'https://gp.songsterr.com/'
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $songArtist = $R[0].artist #| out-host
    $songSongTitle = $R[0].title
    $tmpExt = $($($R[0].source).ToString().Split(".")) #Replace($dlUrlPrefix, "")
    
    $output = "$($songArtist) - $($songSongTitle).$($tmpExt[$tmpExt.Length-1])"

    return $output.ToString()
}

# Get the Download URL's from a list of SongID's...
function GetSongsterrDownloadURLs($SongIDs_List)
{
    write-host "Getting Songsterr download URL's from SongId list file: " -NoNewLine; write-host $SongIDs_List -ForegroundColor Green -NoNewline; write-host "...`n"

    $SongIDs = gc $SongIDs_List
    foreach($sID in $SongIDs)
    {
        write-host "SongID: " -NoNewline; write-host $sID -ForegroundColor DarkGreen
        write-host "DownloadURL: " -NoNewline
        GetSongsterrDownloadURL $sID | out-file -FilePath .\DownloadURLs.txt -Append -Force
        write-host "$(GetSongsterrDownloadURL $sID)" -ForegroundColor Green
    }
}
#endregion


################################
#region MISC UTILITY FUNCTIONS #
################################
# Convert artist/titles to their url equivalent
function CleanText([string]$rawText)
{
    $cText = $rawText.Replace(" ", "-")
    $clText = $cText.replace("(","")
    $cleText = $clText.replace(")","")
    $cleaText = $cleText.replace(".","")
    $cleanText = $cleaText.replace(",","")
    $betterText = $cleanText.replace("'","")
    $bestText = $betterText.replace("/","").replace(">","").replace("<","").replace(":","").replace(";","").replace("?","").replace("!","").replace("&","").replace("#","").replace("%","").replace("*","").replace("{","").replace("}","").replace("[","").replace("]","").replace("|","").replace("=","").replace("+","").replace("~","").replace('`',"").replace("@","").replace("$","").replace("^","").replace('"',"")
    [string]$goodText = $bestText

    return $goodText
}
#endregion


#########################################################
#region Retrieve Song data from songID's list Functions #
#########################################################
function GenerateNewFilenames($songids_list = 'SongIdsFromUrls.txt')
{
    $arrNewFilenames = @()

    $list = gc $songids_list
    foreach($id in $list)
    {
        $outString = GetSongsterrArtistAndTitle $id
        #write-host $outString
        $arrNewFilenames += $outString
    }
    $arrNewFilenames | out-file .\NewFilenames.txt -Force
}
function GenerateArtistsFile($songids_list = 'SongIdsFromUrls.txt')
{
    $arrArtists = @()

    $list = gc $songids_list
    foreach($id in $list)
    {
        $outString = GetSongsterrArtist $id
        #write-host $outString
        $arrArtists += $outString
    }
    $arrArtists | out-file .\Artists.txt -Force
}
function GenerateSongTitlesFile($songids_list = 'SongIdsFromUrls.txt')
{
    $arrSongTitles = @()

    $list = gc $songids_list
    foreach($id in $list)
    {
        $outString = GetSongsterrTitle $id
        #write-host $outString
        $arrSongTitles += $outString
    }
    $arrSongTitles | out-file .\SongTitles.txt -Force
}
#endregion


########################################################
#region Get Songsterr SongID(s) from Songsterr URL(s) #
########################################################
# Get SongId From URL...
function GetSongIdFromURL($url)
{
    $SongIdRegEx = "([a-zA-Z]+(-[a-zA-Z]+)+)"
    $url -match "(tab-s[0-9]+)"
    [string]$rawSongId = $Matches[1].ToString()
    $fName = $url.Remove(0,31)
    $fName -match "(-tab-s[0-9]+)"
    [string]$cleanName = $fName.Replace($Matches[1].ToString(), "").ToString()
    
    
    write-host $cleanName.Replace($Matches[1].ToString(), "") -ForegroundColor Green | out-file SongIdNames.txt -Append -Force
    write-host $rawSongId.Replace("tab-s", "") -ForegroundColor Red

    return [string]$rawSongId.Replace("tab-s", "")
}

# Get multiple SongId's from a list of URL's...
function GetSongIdsFromURLs($URLsList)
{
    $list = gc $URLsList
    foreach($u in $list)
    {
        [string]$sngID = GetSongIdFromURL $u 
        $sngID.Replace("True", "").Replace("False", "").Remove(0,2) | out-file ".\Files\SongIdsFromUrls.txt" -Append -Force
    }
}
#endregion


#####################################################
#region Rename downloaded Songsterr GuitarPro files #
#####################################################
function RenameSongsterrDownloads($path2files, $path2titles)
{
    #ImportSongsterrURLs("H:\.Midi\Seether.xlsx")
    $FileURLsList = ls -Path $path2files #Get-Content D:\urls.txt
    $TitlesList = Get-Content $path2titles #D:\titles.txt
    $indx = 0

    foreach($url in $FileURLsList)
    {
        write-host $url
        $nTitle = $TitlesList[$indx].ToString().Replace(" ","_")
        $neTitle = $nTitle.ToString().Replace(".", "")
        $newTitle = $neTitle.ToString().Replace("'","")
        write-host "$($newTitle).gp5"
        rename-item -Path $url.FullName -NewName "$($newTitle).gp5" -Verbose
        $indx++
    }
}
function RenameSongsterrDownloads($path2files, $artist)
{
    ImportSongsterrURLs("$($path2files)\$($artist)Data-ScrapeStorm.xlsx")
    $FileURLsList = ls -Path $path2files #Get-Content D:\urls.txt
    $TitlesList = Get-Content "$($path2files)\titles.txt"
    $indx = 0

    foreach($url in $FileURLsList)
    {
        write-host $url
        $nTitle = $TitlesList[$indx].ToString().Replace(" ","_")
        $neTitle = $nTitle.ToString().Replace(".", "")
        $newTitle = $neTitle.ToString().Replace("'","")
        write-host "$($newTitle).gp5"
        rename-item -Path $url.FullName -NewName "$($newTitle).gp5" -Verbose
        $indx++
    }
}
#endregion


###########################
#region Custom Tab Object #
###########################
function Create-TabObject($songid="", $artist="", $title="", $tabid="", $url="", $revisionID="", $downloadURL="", $filename="", $fileExt="", $exportID="")
{
    $Tab = New-Object PSObject
    $Tab | Add-Member -MemberType NoteProperty -Name "TabID" -Value $tabid
    $Tab | Add-Member -MemberType NoteProperty -Name "URL" -Value $url  
    $Tab | Add-Member -MemberType NoteProperty -Name "SongID" -Value $songid
    $Tab | Add-Member -MemberType NoteProperty -Name "Artist" -Value $artist
    $Tab | Add-Member -MemberType NoteProperty -Name "Title" -Value $title
    $Tab | Add-Member -MemberType NoteProperty -Name "RevisionID" -Value $revisionID
    $Tab | Add-Member -MemberType NoteProperty -Name "DownloadURL" -Value $downloadURL
    $Tab | Add-Member -MemberType NoteProperty -Name "Filename" -Value $filename
    $Tab | Add-Member -MemberType NoteProperty -Name "FileExt" -Value $fileExt
    $Tab | Add-Member -MemberType NoteProperty -Name "ExportID" -Value $exportID
    return $Tab
}
#endregion


######################
#region UI Functions #
######################
function TextBar($txt)
{
    
}

function TextLog($txt)
{
    write-host "[ " -ForegroundColor Red -NoNewline
    write-host "zH4x™" -ForegroundColor DarkRed -NoNewline
    write-host " ]" -ForegroundColor Red -NoNewline
    write-host " $($txt)"
}

function uiBanner()
{
    write-host ""
    write-host '||[ ' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'Songsterr GP Downloader' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ' ]||' -ForegroundColor Red -BackgroundColor Black
    write-host "       " -NoNewLine
    write-host '|[ ' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'By Zanzo' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ' ]|' -ForegroundColor Red -BackgroundColor Black
    write-host
}

function uiText($txt)
{
    write-host ""
    write-host '[' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'zH4x™' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ']' -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host " $($txt)"
}
#endregion