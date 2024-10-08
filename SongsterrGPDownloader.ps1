#### TO-DO: ######################################################################
## - Output list of generated urls to .txt file                                 ##
## - Scrape GPT download link from each URL in .txt file                        ##
## - Loop each scraped GPT download link and download each file.                ##
## - Rename all files downloaded using their associated artist name/song title. ##
##################################################################################
Import-Module -Name ImportExcel
###### GLOBAL VARIABLES #######
$savedir = "D:\.Tabs\GuitarPro\.songsterr"
$tempPath = ".\temp"
#$SpotifyAPIUrl = "https://api.spotify.com/"


#region Songsterr Search Functions
#########################################################
# Get Songsterr GuitarPro Tabs using Songsterr JSON API #
#########################################################
function Get-SongsterrTabs($startIndex = 0)
{
    $prefix = "http://www.songsterr.com/a/wsa/"
    $apiURL = "https://www.songsterr.com/api/songs?size=250&from="
    $songLinks = @()
    
    $pageMax = 50
    $songIndex = $startIndex
    
    for($i=0; $i -lt $pageMax; $i++)
    {
        $SearchResultsData = Invoke-RestMethod -Uri "$($apiURL)$($songIndex)"
        #loop through all songs in the JSON...
        $indx = 0
        foreach($songJSON in $SearchResultsData)
        {
            $songLinks += "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)"
            write-host "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)" | out-file ".\songsterr_LINKS.txt" -Append -Force
            $indx++
        }##END## SongJSON Loop ###############################################

        #add links from current API page to file...
        $songLinks | out-file ".\SongLinks\SongLinks-pg$($i).txt" -Force -Append
        $songIndex = $startIndex+$i*250
        write-host "[PAGE: $($i) | SONGS: $($indx)]" -ForegroundColor Green -NoNewline
        write-host " SongIndex = $($songIndex)" -ForegroundColor Red
        if($indx -lt 250){break}
    }##END## API PAGE LOOP ################################################

    $songLinks | out-file ".\SongLinks\SongLinks-FULL.txt" -Force -Append
    #$pageCount += $songIndex | out-file H:\.midi\PageCount.txt -Force
}


<#
.SYNOPSIS
Performs a search on Songsterr using the songsterr api.

.DESCRIPTION
Performs a search on Songster and retrieves json data from the songsterr api, then saves it to a file.

.PARAMETER pattern
The search query to use... aka the artist and/or song title to search for...
(e.g. "Metallica" or "Enter Sandman" or "Metallica - Enter Sandman")

.PARAMETER instrument
(Optional) The instrument to search for a tab of... Leave blank for "any" instrument(s).
(e.g. "guitar", "bass", "drums", or "any" for all instruments) 

.PARAMETER startIndex
(Optional) The index in the search results to start from... Leave blank to start from the beginning.

.EXAMPLE
Search-Songsterr "Metallica - Enter Sandman"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Search-Songsterr($pattern, $startIndex = 0)
{
    $escString = [URI]::EscapeUriString($pattern)
    $data = ConvertTo-Json -InputObject (Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)&from=$($startIndex)") -depth 10 
    $saveData = $data
    $saveData | out-file "$($pattern)_searchResults.json"
    return ConvertFrom-Json -InputObject $data -Depth 10
}

function Search-SongsterrTabs([string]$pattern, [int]$startIndex = 0)
{
    $prefix = "http://www.songsterr.com/a/wsa/"
    $apiURL = "https://www.songsterr.com/api/songs?size=250&pattern=$($pattern)&from="
    $songLinks = @()
    $results = ''
    
    #[int]$pageCount = [int]$(gc -Path "H:\.midi\PageCount.txt")
    $pageMax = 42
    $songIndex = $startIndex
    $sIndx = 0
    for($i=0; $i -lt $pageMax; $i++)
    {
        $webAPIDataPage = Invoke-RestMethod -Uri "$($apiURL)$($songIndex)" -UseBasicParsing
        $results = ConvertFrom-Json -InputObject (ConvertTo-Json($webAPIDataPage) -Depth 10) | out-file ".\SearchResults_$($pattern)-pg$($i).json" -Force
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
        $songIndex = $startIndex+($i*250)+$indx
        write-host "[PAGE: $($i+1) | SONGS: $($indx)] " -ForegroundColor Green
        #write-host "$($songIndex) Tabs" -ForegroundColor Red
        $sIndx++
        if($indx -lt 250){break}
    }##END## API PAGE LOOP ################################################
    write-host "Searched " -nonewline; write-host $sIndx -ForegroundColor Cyan -NoNewline; write-host " pages, with " -NoNewline; write-host $songIndex -ForegroundColor Cyan -NoNewline; write-host " tabs found." 
    return $songLinks | out-file ".\SearchResults_$($pattern)-FULL.txt" -Force -Append
    #$pageCount += $songIndex | out-file H:\.midi\PageCount.txt -Force
    #return ConvertTo-Json -InputObject (invoke-restmethod -uri "https://www.songsterr.com/api/songs?size=250&from=0&pattern=$($pattern)") -depth 10 #| out-file TEMPFILE.json
}
#endregion



#region Get-SongsterrTabsByArtist
########################################################
## Search For Tabs By Artist Using Songsterr JSON API ##
########################################################
# Search for Songsterr Tabs by Artist Name or Song Title...
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
    $SearchResultsData = Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)"
    $webJSON = ConvertFrom-Json -InputObject "$($SearchResultsData)" -Depth 10
    write-host $webJSON
    ## Using Invoke-WebRequest
    #$SearchResultsData = ConvertFrom-JSON (Invoke-WebRequest -uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)")

    ## The download information is stored in the "assets" section of the data
    $songs = $webJSON.assets #$SearchResultsData
    #$SearchResultsData | Get-Member

    # Generate a http URL for each song...
    foreach($song in $SearchResultsData)
    {
        write-host "http://www.songsterr.com/a/wsa/" -NoNewline
        write-host "$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)" | out-file "SearchResults_$($artistName).txt" -Force
        $results += "http://www.songsterr.com/a/wsa/$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)"
    }
    $results | out-file ".\SearchResults\$($SearchString).txt" -Force
    
    return $results
}
# Get Songsterr tabs by multiple Artists from a .txt list of artists...
function GetSongsterrTabsByArtistList($artistlist)
{
    $list = gc $artistlist
    foreach($a in $list)
    {
        Get-SongsterrTabsByArtist $a
    }
}
#endregion


#region OLD: Combine Search Results Functions
##
# Combine all search results in the ".\SearchResults\" directory
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
#endregion


#region Songsterr: Download Tab By SongID
<#
.SYNOPSIS
Retrieves tab metadata from Songsterr API and downloads the Guitar Pro tab.

.DESCRIPTION
This function retrieves the latest revision metadata for a given Songsterr song ID, extracts the Guitar Pro download URL, downloads the tab, and renames the file to include the artist and title.

.PARAMETER SongID
The Songsterr song ID for the tab to download.

.EXAMPLE
DownloadTabBySongID -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
Revised: 2024-09-21
#>
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
    $destinationPath = ".\Downloads\$($oldFilename)"
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
    # Define the new file name
    $newFileName = "$($artist) - $($title)$($oldFilename.Replace("export",''))"
    # Rename the file
    Rename-Item -Path $destinationPath -NewName "$($newFileName)"

    Write-Host "Guitar Pro tab downloaded and renamed to " -NoNewLine; write-Host $newFileName -ForegroundColor Green
}
#endregion


#region Songsterr: Get SongID from URL Functions
$cookie = 'OrigRef=d3d3Lmdvb2dsZS5jb20=; _ga=GA1.2.563324618.1641686257; G_ENABLED_IDPS=google; __gads=ID=b5de266b76d30fa8:T=1641686257:S=ALNI_MZxgEGqVWRkMMew-r_CunkutRPrQg; SongsterrL=b0b18683873fd827048dff32450b36910f6bba9e8ef30a9f; cto_bundle=uLgR3V94aUdUbzhmQVpDeW1nR3NlbHlReThHJTJCNlBGSUNnZklXeVpQREluamU3RmZTR21vZEtTVXdmJTJCOEtIZnVIbU5iZiUyRndCeFFvbTEyS3NES21EOUJ5N2ZHJTJGJTJGSmI0MUdUTGNGbEpsTm94RDE0TnF4V2lBRXRjbUx2NHZTQ2N1R0pzclNZb1VrMFpHUmglMkZTd0s4cXN3U2dNSkElM0QlM0Q; ScrShwn-svws=true; LastRef=d3d3Lmdvb2dsZS5jb20=; EE_STORAGE=["video_walkthrough","comments_removal"]; lastSeenTrack=/a/wsa/falling-in-reverse-wait-and-see-half-solo-tab-s398766; experiments={"aa":"on","sound_v4":"off","comments_removal":"on","new_plus_banner":"off"}; _gid=GA1.2.1968037562.1656242890; amp_9121af=XrOZ72J_mkX5E6aGJkftn4.MjMyMDYzMA==..1g6gt3qtj.1g6gt93ho.2p.2p.5i; SongsterrT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIyMzIwNjMwIiwiZW1haWwiOiJ6Q2xvbmVIZXJvQGdtYWlsLmNvbSIsIm5hbWUiOiJ6Q2xvbmVIZXJvIiwicGxhbiI6InBsdXMiLCJzdWJzY3JpcHRpb24iOnsic3RhdHVzIjoiYWN0aXZlIiwidHlwZSI6ImJyYWludHJlZSIsInN0YXJ0RGF0ZSI6IjIwMjItMDUtMDhUMDQ6NTE6MzQuMDAwWiIsImVuZERhdGUiOm51bGwsImNhbmNlbGxhdGlvbkRhdGUiOm51bGx9LCJzcmFfbGljZW5zZSI6Im5vbmUiLCJnb29nbGUiOiIxMDExNDgyNDE3ODYwODgwNDQxMzQiLCJpYXQiOjE2NTYyNzc2NjQsImlkIjoiMjMyMDYzMCJ9.e-cSj5xaosVcet1kNciKL2cxmiOu0lGlREz3HFNLhao'
#$dlPrefix = 'https://d12drcwhcokzqv.cloudfront.net/'
$dlPrefix = 'https://gp.songsterr.com/'
$SongIDs = gc -Path D:\SongIDs.txt
$data = @()
$fileData = @()

##
# Get SongId From URL...
function GetSongIdFromURL([string]$url, [switch]$Verbose)
{
    $SongIdRegEx = "([a-zA-Z]+(-[a-zA-Z]+)+)"
    $url -match "(tab-s[0-9]+)"
    $rawSongId = $Matches[1].ToString()
    $fName = $url.Remove(0,31)
    $fName -match "(-tab-s[0-9]+)"
    [string]$cleanName = $fName.Replace($Matches[1].ToString(), "").ToString()
    if($Verbose){
        write-host $cleanName.Replace($Matches[1].ToString(), "") -ForegroundColor Green #| out-file SongIdNames.txt -Append -Force
        write-host $rawSongId.Replace("tab-s", "") -ForegroundColor Red
    }
    return $rawSongId.Replace("tab-s", "").ToInteger()
}
##
# Get multiple SongId's from a list of URL's...
function GetSongIdsFromURLs($URLsList, $out_path=".\Files")
{
    $list = gc $URLsList
    foreach($u in $list)
    {
        [string]$sngID = GetSongIdFromURL $u 
        $sngID.Replace("True", "").Replace("False", "").Remove(0,2) | out-file "$($out_path)\SongIdsFromUrls.txt" -Append -Force
    }
}
#endregion


#region Songsterr: MetaData Functions by SongID
## 
# Get all download related metadata from a SongID...
function Get-SongsterrDownloadData($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    
    $RevisionId = $R[0].revisionId #| out-host
    $Tracks = $R[0].tracks #| out-host
    $Title = $R[0].title #| out-host
    $Artist = $R[0].artist #| out-host

    $DownloadURL = $R[0].source #| out-host
    $fileExt = "$($R[0].source.SubString($R[0].source.Length - 3).Replace('.', ''))"
    $nFilename = "$($Artist) - $($Title).$($fileExt)" #| out-host

    $data += "$($R[0].revisionId)`n"
    $data += "$($R[0].title)`n"
    $data += "$($R[0].artist)`n"
    $data += "$($R[0].source)`n"
    $data += "$($nFilename)`n"
    $data 

    return $data | out-file .\temp\songsterrData.txt -Append -Force
}
##
# Get a Download URL from a Songsterr SongID...
function GetSongsterrDownloadURL($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getDownloadURL = $R[0].source
    
    return $($R[0].source).ToString()
}
##
# Get the latest Revision ID from a Songsterr SongID...
function GetSongsterrRevisionID($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getRevisionID = $R[0].revisionId
    
    return $R[0].revisionId.ToString()
}
##
# Get the Song Title from a Songsterr SongID...
function GetSongsterrTitle($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getTitle = $R[0].title
    
    return $($R[0].title).ToString()
}
##
# Get the Artist Name from a Songsterr SongID...
function GetSongsterrArtist($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getArtist = $R[0].artist
    
    return $($R[0].artist).ToString()
}
##
# Get the Tracks from a Songsterr SongID...
function GetSongsterrTracks($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $getTracks = $R[0].tracks
    
    return $R[0].tracks
}
##
# Get the Artist and SongTitle from a Songsterr SongID...
function GetSongsterrArtistAndTitle($songid)
{
    $dlUrlPrefix = 'https://gp.songsterr.com/'
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $songArtist = $R[0].artist #| out-host
    $songSongTitle = $R[0].title
    $tmpExt = $($($R[0].source).ToString()).Replace($dlUrlPrefix, "")
    
    $output = "$($songArtist) - $($songSongTitle).$($tmpExt)"

    return $output.ToString()
}
##
# Get the Download URL's from a list of SongID's...
function GetSongsterrDownloadURLs($SongIDs_List)
{
    write-host "Getting Songsterr download URL's from SongId list file: " -NoNewLine; write-host $SongIDs_List -ForegroundColor Green -NoNewline; write-host "...`n"

    $SongIDs = Get-Content $SongIDs_List
    foreach($sID in $SongIDs)
    {
        write-host "SongID: " -NoNewline; write-host $sID -ForegroundColor DarkGreen
        write-host "DownloadURL: " -NoNewline
        $dlUrl = GetSongsterrDownloadURL $sID | out-tee -FilePath .\DownloadURLs.txt -Append -Force
        write-host "$($dlUrl)" -ForegroundColor Green
    }
}
#endregion


#region Songsterr: Misc Utility Functions
# Convert artist/titles to their url equivalent
function CleanText([string]$rawText)
{
    $cText = $rawText.Replace(" ", "-")
    $clText = $cText.replace("(","")
    $cleText = $clText.replace(")","")
    $cleaText = $cleText.replace(".","")
    $cleanText = $cleaText.replace(",","")
    $betterText = $cleanText.replace("'","")
    [string]$goodText = $betterText

    return $goodText
}
#endregion


#region YouTube-to-MP3 Functions
<#
.SYNOPSIS
Get the YouTube-to-MP3 Download page URL from a YouTube VideoID.

.DESCRIPTION
Returns the URL to a YouTube-to-MP3 download page from a YouTube VideoID (vID).

.PARAMETER vID
The YouTube VideoID to get the download page URL for.

.EXAMPLE
Get-YouTubeMP3('9oWclEZprdc')
#>
function Get-YouTubeMP3([string]$vID)
{
    #$ytVideoID = Get-Content "./savedata/official/youtube/$($SearchString).txt" #$videoIDorURL
    return "https://y2hub.cc/enesto/download?src=query?url=$($vID)"
}
###################################################
## Get Songsterr SongID(s) from Songsterr URL(s) ##
###################################################
# Get SongId From URL...
function GetSongIdFromURL([string]$url)
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
function GetSongIdsFromURLs($URLsList, $out_path=".\Files")
{
    $list = gc $URLsList
    foreach($u in $list)
    {
        [string]$sngID = GetSongIdFromURL $u 
        $sngID.Replace("True", "").Replace("False", "").Remove(0,2) | out-file "$($out_path)\SongIdsFromUrls.txt" -Append -Force
    }
}
#endregion


#region UI/Display Functions
########################################################################################################
#### UI/DISPLAY RELATED FUNCTIONS #####
#######################################
function TextBar($txt)
{
    write-host "[ " -ForegroundColor Red -NoNewline
    write-host $txt -ForegroundColor DarkRed -NoNewline
    write-host " ]" -ForegroundColor Red -NoNewline
}
function TextBarW($txt)
{
    write-host "[ " -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host $txt -ForegroundColor DarkRed -BackgroundColor Black -NoNewline
    write-host " ]" -ForegroundColor Red -BackgroundColor Black -NoNewline
}
function TextBarL($title, $txt)
{
    TextBarW($title); write-host " $($txt)"
}

function TextLog($txt)
{
    TextBar("SongsterrGPDownloader"); write-host " $($txt)"
}

function uiBanner()
{
    write-host ""
    write-host '||[ ' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'zRocksmith Utilities' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
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
    write-host 'zRS' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ']' -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host " $($txt)"
}
function uiBannerText($txt)
{
    write-host ""
    write-host '||[ ' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'zRS' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ' ]||[ ' -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host 'Rocksmith Utilities' -ForegroundColor DarkGray -BackgroundColor Black -NoNewline
    write-host ' ]||' -ForegroundColor Red -BackgroundColor Black
    write-host " $($txt)"
}
function uiBannerText($txt, [System.ConsoleColor]$color = "White")
{
    write-host ""
    write-host '||[ ' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'zRS' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ' ]||[ ' -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host $txt -ForegroundColor $color -BackgroundColor Black -NoNewline
    write-host ' ]||' -ForegroundColor Red -BackgroundColor Black
}
#endregion