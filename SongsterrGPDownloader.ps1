#### DOT SOURCE SCRIPTS ####
. $PSScriptRoot\ug.ps1
. $PSScriptRoot\tunebat.ps1
. $PSScriptRoot\youtube.ps1
. $PSScriptRoot\genius.ps1
. $PSScriptRoot\azlyrics.ps1

#### IMPORT MODULES ####
Import-Module -Name ImportExcel # Excel (.xlsx) File Import/Export Module

###### GLOBAL VARIABLES #######
$Script:save_path = "D:\.Tabs\GuitarPro\.songsterr"
$Script:temp_path = "$($env:TEMP)\SongsterrGPDownloader"

# Check if the temp directory exists, if not create it
if(-not (test-path $temp_path)){mkdir $temp_path}


#region Songsterr Tab Search Functions
###################################################################
<#
.SYNOPSIS
Performs a search on Songsterr using the songsterr api.

.DESCRIPTION
Performs a search on Songster and retrieves json data from the songsterr api, then saves it to a file.

.PARAMETER pattern
The search query to use... aka the artist and/or song title to search for...
(e.g. "Metallica" or "Enter Sandman" or "Metallica - Enter Sandman")

.PARAMETER startIndex
(Optional) The index in the search results to start from... Leave blank to start from the beginning. 

.EXAMPLE
Search-Songsterr "Metallica - Enter Sandman"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Search-Songsterr([string]$pattern, [int]$startIndex = 0)
{
    $escString = [URI]::EscapeUriString($pattern)
    $data = ConvertTo-Json -InputObject (Invoke-RestMethod -Uri "https://www.songsterr.com/api/songs?size=250&pattern=$($escString)&from=$($startIndex)") -depth 10 
    $saveData = $data
    $saveData | out-file "$($temp_path)\SearchResults\$($pattern)_searchResults.json"
    return ConvertFrom-Json -InputObject $data -Depth 10
}

<#
.SYNOPSIS
Search for Songsterr tabs by artist name or song title.

.DESCRIPTION
This function searches the Songsterr API for tabs by artist name and/or song title, and returns a list of URLs to the tabs.

.PARAMETER pattern
The search query to use... aka the artist and/or song title to search for...

.PARAMETER startIndex
(Optional) The index in the search results to start from... Leave blank to start from the beginning.

.EXAMPLE
Search-SongsterrTabs "Metallica - Enter Sandman"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Search-SongsterrTabs([string]$pattern, [int]$startIndex = 0)
{
    $apiURL = "https://www.songsterr.com/api/songs?size=250&pattern=$($pattern)&from="
    $songLinks,$saveLinks = @()
    $results = ''
    
    $pageMax = 42
    $songIndex = $startIndex
    $sIndx = 0
    for($i=0; $i -lt $pageMax; $i++)
    {
        $webAPIDataPage = Invoke-RestMethod -Uri "$($apiURL)$($songIndex)" -UseBasicParsing
        $results = ConvertFrom-Json -InputObject (ConvertTo-Json($webAPIDataPage) -Depth 10) | out-file "$($temp_path)\SearchResults\SearchResults_$($pattern)-pg$($i).json" -Force
        write-host $results

        #loop through all songs in the JSON data...
        $indx = 0
        $saveLinks.clear
        foreach($songJSON in $webAPIDataPage)
        {
            $tabLink = "http://www.songsterr.com/a/wsa/$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)"

            $songLinks += $tabLink
            write-host $tabLink | out-file "$($temp_path)\songsterr_LINKS.txt" -Append -Force           #<-- add the link to a file...
            $saveLinks += $tabLink
            $saveLinks | out-file "$($temp_path)\SearchResults\SearchResults-pg$($i).txt" -Force -Append
            $indx++
        }

        #add links from current API page to a file...
        $saveLinks | out-file "$($temp_path)\SearchResults\SearchResults_$($pattern)-pg$($i).txt" -Force
        $songIndex = $startIndex+($i*250)+$indx
        write-host "[PAGE: $($i+1) | SONGS: $($indx)] " -ForegroundColor Green
        
        $sIndx++
        if($indx -lt 250){break}
    }

    write-host "Searched " -nonewline; write-host $sIndx -ForegroundColor Cyan -NoNewline; write-host " pages, with " -NoNewline; write-host $songIndex -ForegroundColor Cyan -NoNewline; write-host " tabs found." 
    return $songLinks | out-file "$($temp_path)\SearchResults\SearchResults_$($pattern)-FULL.txt" -Force -Append
}
#endregion


#region Songsterr Get Tabs Function(s)
<#
.SYNOPSIS
Get Songsterr tabs using the Songsterr API.

.DESCRIPTION
This function retrieves a list of Songsterr tabs using the Songsterr API and saves the URLs to a text file.

.PARAMETER startIndex
The index in the search results to start from... Leave blank to start from the beginning.

.EXAMPLE
Get-SongsterrTabs

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
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
            write-host "$($prefix)$(CleanText($songJSON.artist))-$(CleanText($songJSON.title))-tab-s$($songJSON.songId)" | out-file "$($temp_path)\songsterr_LINKS.txt" -Append -Force
            $indx++
        }##END## SongJSON Loop ###############################################

        #add links from current API page to file...
        $saveLinks = $songLinks 
        $saveLinks | out-file "$($temp_path)\SongLinks\SongLinks-pg$($i).txt" -Force -Append
        $songIndex = $startIndex+$i*250
        write-host "[PAGE: $($i) | SONGS: $($indx)]" -ForegroundColor Green -NoNewline
        write-host " SongIndex = $($songIndex)" -ForegroundColor Red
        # End loop if less than 250 songs are found on the page...
        if($indx -lt 250){break}
    }##END## API PAGE LOOP ################################################

    $songLinks | out-file "$($temp_path)\SongLinks\SongLinks-FULL.txt" -Force -Append
    #$pageCount += $songIndex | out-file H:\.midi\PageCount.txt -Force
}
#endregion


#region Songsterr Get tabs by Artist Functions
<#
.SYNOPSIS
Search for Songsterr tabs by artist name.

.DESCRIPTION
This function searches the Songsterr API for tabs by artist name, and returns a list of URLs to the tabs.

.PARAMETER artistName
The name of the artist to search for.

.EXAMPLE
Get-SongsterrTabsByArtist -artistName "Metallica"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrTabsByArtist($artistName)
{
    $results = @()

    if(!$artistName){
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
    write-host $songs
    #$SearchResultsData | Get-Member

    # Generate a http URL for each song...
    foreach($song in $SearchResultsData)
    {
        write-host "http://www.songsterr.com/a/wsa/" -NoNewline
        write-host "$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)" | out-file "$($temp_path)\SearchResults\SearchResults_$($artistName).txt" -Force
        $results += "http://www.songsterr.com/a/wsa/$(CleanText($song.artist))-$(CleanText($song.title))-tab-s$($song.songId)"
    }
    $results | out-file "$($temp_path)\SearchResults\$($SearchString).txt" -Force
    
    return $results
}

<#
.SYNOPSIS
Search for Songsterr tabs by a list of artist names.

.DESCRIPTION
This function reads a list of artist names from a text file and searches the Songsterr API for tabs by each artist, returning a list of URLs to the tabs.

.PARAMETER ArtistList
The path to the text file containing a list of artist names.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
GetSongsterrTabsByArtistList -ArtistList "artists.txt"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrTabsByArtistList([string]$ArtistList, [switch]$Verbose)
{
    $tabs = @()
    $results = @()
    $list = Get-Content $ArtistList
    foreach($a in $list)
    {
        $artistTabs = Get-SongsterrTabsByArtist $a
        foreach($t in $artistTabs){
            if($Verbose){write-host $t}
            $tabs += $t
        }
        if($Verbose){write-host "Artist: $($a) | Tabs: $($artistTabs.Count)"}
        $results += $artistTabs
    }
    if($Verbose){write-host "Total Tabs: $($tabs.Count)"}
    $tabs | out-file "$($temp_path)\SearchResults\SearchResults-FULL.txt" -Force -Append
    return $results
}
#endregion


#region Songsterr Get Revisions Data Functions
# Get revision data for a Songsterr tab, by SongID, using the Songsterr API
<#
.SYNOPSIS
Retrieves the revision data for a Songsterr tab.

.DESCRIPTION
This function retrieves the revision data for a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-RevisionsData "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-RevisionsData($SongID)
{
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0"
    $response = Invoke-RestMethod -Uri "https://www.songsterr.com/api/meta/$($SongID)/revisions" `
    -WebSession $session `
    -Headers @{
    "sec-ch-ua-platform"="`"Windows`""
    "Referer"="https://www.songsterr.com"
    "sec-ch-ua"="`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
    "DNT"="1"
    "sec-ch-ua-mobile"="?0"
    }

    return $response
}

# Get revision data for a Songsterr tab, by URL, using the Songsterr API
<#
.SYNOPSIS
Retrieves the revision data for a Songsterr tab.

.DESCRIPTION
This function retrieves the revision data for a Songsterr tab using the Songsterr API.

.PARAMETER url
The URL of the Songsterr tab.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-TabRevisions "https://www.songsterr.com/a/wsa/metallica-enter-sandman-tab-s534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-TabRevisions([string]$url, [switch]$Verbose)
{
    # Get the Song ID from the URL
    $url -match '(?>.*\-tab\-s)(?<songid>[0-9]*)' | Out-Null
    $sID = $matches['songid']
    # Get the revision data for the Song ID
    $revisions = Get-RevisionsData($sID)
    if($Verbose){
        write-host "`nTotal Revisions: " -nonewline; write-host ($revisions.count - 1) -ForegroundColor Cyan
        write-host "-------------------" -ForegroundColor Gray
        $indx = 0
        foreach($rev in $revisions){
            write-host "[" -nonewline; write-host $($indx) -nonewline -ForegroundColor Green; write-host "] $($rev.revisionId)"
            $indx++    
        }
        $revisions[0]
    }
    return $revisions
}
#endregion


#region OLD Combine Search Results Functions

# Combine all search results in the ".\SearchResults\" directory
<#
.SYNOPSIS
Combine all search results in the ".\SearchResults\" directory.

.DESCRIPTION
This function combines all search results in the ".\SearchResults\" directory into a single text file.

.EXAMPLE
CombineAllSearchResults

.NOTES
Author: Zanzo
#>
function CombineAllSearchResults()
{
    Set-Location .\SearchResults
    $results = @()
    $getSearchResults = Get-ChildItem $($temp_path)\* -Include *.txt
    foreach($r in $getSearchResults)
    {
        $SearchData = Get-Content $r
        write-host $SearchData | out-file $($temp_path)\SearchData.txt -Append -Force
        $results += $SearchData 
    }
    Set-Location ..
    $results | out-file $($temp_path)\CombinedSearchResults.txt -Force
    
    return $results
}
<#
.SYNOPSIS
Combine all search results in the ".\SearchResults\" directory.

.DESCRIPTION
This function combines all search results in the ".\SearchResults\" directory into a single text file.

.EXAMPLE
CombineAllSearchResults

.NOTES
Author: Zanzo
#>
function GetCombinedSearchResultsTabData()
{
    write-host "Getting SongID's from CombinedSearchResults.txt..."
    pause
    Get-SongIdsFromUrls CombinedSearchResults.txt
    write-host "Getting DownloadURL's from SongID's..."
    pause
    Get-SongsterrDownloadURLs SongIdsFromUrls.txt
    #write-host "Downloading all Tabs from DownloadURLs.txt..."
    #DownloadSongsterrTabs
    write-host "COMPLETE!"
}
#endregion


#region Songsterr Download Tab By SongID
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
    $destinationPath = "$($save_path)\SongsterrGPDownloader\$($oldFilename)"
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
    # Define the new file name
    $newFileName = "$($artist) - $($title)$($oldFilename.Replace("export",''))"
    # Rename the file
    Rename-Item -Path $destinationPath -NewName "$($newFileName)"

    Write-Host "Guitar Pro tab downloaded and renamed to " -NoNewLine; write-Host $newFileName -ForegroundColor Green
}
#endregion


#region Songsterr Get SongID from URL Functions
###########################################################
# Get SongId From URL...
<#
.SYNOPSIS
Get the SongID from a Songsterr tab URL.

.DESCRIPTION
This function extracts the SongID from a Songsterr tab URL.

.PARAMETER url
The URL of the Songsterr tab.

.EXAMPLE
Get-SongIdFromUrl "https://www.songsterr.com/a/wsa/metallica-enter-sandman-tab-s534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongIdFromUrl([string]$url)
{
    $url -match '(?>.*\-tab\-s)(?<songid>[0-9]*)'
    return $matches['songid']
}

#$cookie = 'OrigRef=d3d3Lmdvb2dsZS5jb20=; _ga=GA1.2.563324618.1641686257; G_ENABLED_IDPS=google; __gads=ID=b5de266b76d30fa8:T=1641686257:S=ALNI_MZxgEGqVWRkMMew-r_CunkutRPrQg; SongsterrL=b0b18683873fd827048dff32450b36910f6bba9e8ef30a9f; cto_bundle=uLgR3V94aUdUbzhmQVpDeW1nR3NlbHlReThHJTJCNlBGSUNnZklXeVpQREluamU3RmZTR21vZEtTVXdmJTJCOEtIZnVIbU5iZiUyRndCeFFvbTEyS3NES21EOUJ5N2ZHJTJGJTJGSmI0MUdUTGNGbEpsTm94RDE0TnF4V2lBRXRjbUx2NHZTQ2N1R0pzclNZb1VrMFpHUmglMkZTd0s4cXN3U2dNSkElM0QlM0Q; ScrShwn-svws=true; LastRef=d3d3Lmdvb2dsZS5jb20=; EE_STORAGE=["video_walkthrough","comments_removal"]; lastSeenTrack=/a/wsa/falling-in-reverse-wait-and-see-half-solo-tab-s398766; experiments={"aa":"on","sound_v4":"off","comments_removal":"on","new_plus_banner":"off"}; _gid=GA1.2.1968037562.1656242890; amp_9121af=XrOZ72J_mkX5E6aGJkftn4.MjMyMDYzMA==..1g6gt3qtj.1g6gt93ho.2p.2p.5i; SongsterrT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIyMzIwNjMwIiwiZW1haWwiOiJ6Q2xvbmVIZXJvQGdtYWlsLmNvbSIsIm5hbWUiOiJ6Q2xvbmVIZXJvIiwicGxhbiI6InBsdXMiLCJzdWJzY3JpcHRpb24iOnsic3RhdHVzIjoiYWN0aXZlIiwidHlwZSI6ImJyYWludHJlZSIsInN0YXJ0RGF0ZSI6IjIwMjItMDUtMDhUMDQ6NTE6MzQuMDAwWiIsImVuZERhdGUiOm51bGwsImNhbmNlbGxhdGlvbkRhdGUiOm51bGx9LCJzcmFfbGljZW5zZSI6Im5vbmUiLCJnb29nbGUiOiIxMDExNDgyNDE3ODYwODgwNDQxMzQiLCJpYXQiOjE2NTYyNzc2NjQsImlkIjoiMjMyMDYzMCJ9.e-cSj5xaosVcet1kNciKL2cxmiOu0lGlREz3HFNLhao'
#$dlPrefix = 'https://d12drcwhcokzqv.cloudfront.net/'
#$dlPrefix = 'https://gp.songsterr.com/'
$SongIDs = Get-Content -Path D:\SongIDs.txt
$data = @()
#$fileData = @()

# *OLD* Get SongId From URL...
<#
.SYNOPSIS
Get the SongID from a Songsterr tab URL.

.DESCRIPTION
This function extracts the SongID from a Songsterr tab URL.

.PARAMETER url
The URL of the Songsterr tab.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-SongIdFromUrl "https://www.songsterr.com/a/wsa/metallica-enter-sandman-tab-s534532"

.NOTES
*Use the newer version of this function instead.*
Author: Zanzo
Date: 2022-03-01
#>
function GetSongIdFromURL([string]$url, [switch]$Verbose)
{
    #$SongIdRegEx = "([a-zA-Z]+(-[a-zA-Z]+)+)"
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

# Get multiple SongId's from a list of URL's...
<#
.SYNOPSIS
Get the SongID from a list of Songsterr tab URLs.

.DESCRIPTION
This function extracts the SongID from a list of Songsterr tab URLs.

.PARAMETER URLsList
The path to the text file containing a list of Songsterr tab URLs.

.EXAMPLE
GetSongIdsFromURLs "SongsterrURLs.txt"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function GetSongIdsFromURLs([string]$URLsList)
{
    $list = Get-Content $URLsList
    foreach($u in $list)
    {
        [string]$sngID = GetSongIdFromURL $u 
        $sngID.Replace("True", "").Replace("False", "").Remove(0,2) | out-file ".\SongIdsFromUrls.txt" -Append -Force
    }
}
#endregion


#region Songsterr Tag Functions

#endregion


#region Songsterr MetaData Functions by SongID
#######################################################
# Get all download related metadata from a SongID...
<#
.SYNOPSIS
Get the download metadata for a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the download metadata for a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
Get-SongsterrDownloadData -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
Revised: 2024-09-21
#>
function Get-SongsterrDownloadData([int]$songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json

    $fileExt = "$($R[0].source.SubString($R[0].source.Length - 3).Replace('.', ''))"
    $nFilename = "$($R[0].artist) - $($R[0].title).$($fileExt)" #| out-host

    $data = @()
    $data += "$($R[0].revisionId)`n"
    $data += "$($R[0].title)`n"
    $data += "$($R[0].artist)`n"
    $data += "$($R[0].source)`n"
    $data += "$($nFilename)`n"
    $data 

    return $data
}

# Get a Download URL from a Songsterr SongID...
<#
.SYNOPSIS
Get the download URL for a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the download URL for a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrDownloadURL -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrDownloadURL($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    return $($R[0].source).ToString()
}

# Get the latest Revision ID from a Songsterr SongID...
<#
.SYNOPSIS
Get the latest revision ID for a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the latest revision ID for a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrRevisionID -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrRevisionID($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    return $R[0].revisionId.ToString()
}

# Get the Song Title from a Songsterr SongID...
<#
.SYNOPSIS
Get the title of a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the title of a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrTitle -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrTitle($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json    
    return $($R[0].title).ToString()
}

# Get the Artist Name from a Songsterr SongID...
<#
.SYNOPSIS
Get the artist name of a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the artist name of a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrArtist -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrArtist($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    return $($R[0].artist).ToString()
}

# Get the Tracks from a Songsterr SongID...
<#
.SYNOPSIS
Get the tracks of a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the tracks of a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrTracks -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrTracks($songid)
{
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    return $R[0].tracks
}

# Get the Artist and SongTitle from a Songsterr SongID...
<#
.SYNOPSIS
Get the artist and title of a Songsterr tab using the Songsterr API.

.DESCRIPTION
This function retrieves the artist and title of a Songsterr tab using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrArtistAndTitle -SongID "534532"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrArtistAndTitle($songid)
{
    $dlUrlPrefix = 'https://gp.songsterr.com/'
    $R = Invoke-RestMethod -uri "https://songsterr.com/api/meta/$($songid)/revisions" #-OutFile H:\.midi\json.json
    $songArtist = $R[0].artist #| out-host
    $songSongTitle = $R[0].title
    $tmpExt = $($($R[0].source).ToString()).Replace($dlUrlPrefix, "")
    
    $output = "$($songArtist) - $($songSongTitle).$($tmpExt)"

    return $output.ToString()
}

# Get the Download URL's from a list of SongID's...
<#
.SYNOPSIS
Get the download URL's for a list of Songsterr tabs using the Songsterr API.

.DESCRIPTION
This function retrieves the download URL's for a list of Songsterr tabs using the Songsterr API.

.PARAMETER SongID
The Songsterr song ID for the tab.

.EXAMPLE
GetSongsterrDownloadURLs "SongIds.txt"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function Get-SongsterrDownloadURLs([string]$SongIDs_List)
{
    write-host "Getting Songsterr download URL's from SongId list file: " -NoNewLine; write-host $SongIDs_List -ForegroundColor Green -NoNewline; write-host "...`n"

    $downloadURLs = @()
    $SongIDs = Get-Content $SongIDs_List
    foreach($sID in $SongIDs)
    {
        write-host "SongID: " -NoNewline; write-host $sID -ForegroundColor DarkGreen
        write-host "DownloadURL: " -NoNewline
        $dlUrl = Get-SongsterrDownloadURL $sID 
        $downloadURLs += $dlUrl | out-tee -FilePath "$($temp_path)\DownloadURLs.txt" -Append -Force
        write-host $dlUrl -ForegroundColor Green
    }
}
#endregion


#region SongsterrAI Generate Guitar Pro Tab from YouTube video using SongsterrAI API Function(s)
#################################################################################################
<#
.SYNOPSIS
Generate a Guitar Pro tab from a YouTube video using the Songsterr AI API.

.DESCRIPTION
This function generates a Guitar Pro tab from a YouTube video using the Songsterr AI API.

.PARAMETER Title
The title of the song that you want to generate a Guitar Pro tab for.

.PARAMETER Artist
The artist name of the song that you want to generate a Guitar Pro tab for.

.PARAMETER VideoId
The VideoID of the YouTube video to generate the Guitar Pro tab from.
(note: You can right-click on any YouTube video and select "Copy video URL" to get the VideoID)

.EXAMPLE
New-SongsterrAITab -VideoId "534532" -Title "Enter Sandman" -Artist "Metallica"

.NOTES
Author: Zanzo
Date: 2024-09-01
Updated: 2024-10-25
#>
function New-SongsterrAITab([string]$SongTitle, [string]$Artist, [string]$VideoId)
{
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.Cookies.Add((New-Object System.Net.Cookie("lastSeenTrack", "/a/wsa/jason-aldean-rearview-town-drum-tab-s737929", "/", "www.songsterr.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("LastRef", "d3d3LnNvbmdzdGVyci5jb20=", "/", "www.songsterr.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("sr_vpt10", "7", "/", "www.songsterr.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("SongsterrT", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIyMzIwNjMwIiwiZW1haWwiOiJ6Q2xvbmVIZXJvQGdtYWlsLmNvbSIsIm5hbWUiOiJ6Q2xvbmVIZXJvIiwicGxhbiI6ImZyZWUiLCJzdWJzY3JpcHRpb24iOm51bGwsInBlcm1pc3Npb25zIjpbXSwic3JhX2xpY2Vuc2UiOiJub25lIiwiZ29vZ2xlIjoiMTAxMTQ4MjQxNzg2MDg4MDQ0MTM0IiwiaWF0IjoxNzI3MDE0NDExLCJpZCI6IjIzMjA2MzAifQ.cFBxdTGqU7kpFGuSK_CtoS88NoyTrhWpZiZ6KTxqrfs", "/", "www.songsterr.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("hasEditorBonus", "2024-09-22T13:29:45.638Z", "/", "www.songsterr.com")))
  $response = Invoke-WebRequest -UseBasicParsing -Uri "https://www.songsterr.com/api/song/transcribe-song" `
  -Method POST `
  -WebSession $session `
  -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0" `
  -Headers @{
  "Accept" = "*/*"
    "Accept-Language" = "en-US,en;q=0.5"
    "Accept-Encoding" = "gzip, deflate, br, zstd"
    "Referer" = "https://www.songsterr.com/a/wa/submit"
    "Origin" = "https://www.songsterr.com"
    "DNT" = "1"
    "Sec-Fetch-Dest" = "empty"
    "Sec-Fetch-Mode" = "cors"
    "Sec-Fetch-Site" = "same-origin"
    "Priority" = "u=0"
  } `
  -ContentType "application/json" `
  -Body "{`"title`":`"$($SongTitle)`",`"artist`":`"$($Artist)`",`"videoId`":`"$($VideoId)`"}"

  return $response.Content
}
#endregion


#region Misc Utility Functions
###############################################
# Convert artist/titles to their url equivalent
<#
.SYNOPSIS
Convert a string to a URL-friendly format.

.DESCRIPTION
This function converts a string to a URL-friendly format by replacing spaces with hyphens and removing special characters.

.PARAMETER rawText
The raw text to convert.

.EXAMPLE
CleanText "Metallica - Enter Sandman"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
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
#################################################
#endregion


#region UI/Display FUNCTIONS
###############################################
<#
.SYNOPSIS
Display a text bar.

.DESCRIPTION
This function displays a text bar with the specified text.

.PARAMETER txt
The text to display in the text bar.

.EXAMPLE
TextBar "Downloading tabs..."

.NOTES
Author: Zanzo
#>
function TextBar($txt)
{
    write-host "[ " -ForegroundColor Red -NoNewline
    write-host $txt -ForegroundColor DarkRed -NoNewline
    write-host " ]" -ForegroundColor Red -NoNewline
}

<#
.SYNOPSIS
Display a text bar with a title and text.

.DESCRIPTION
This function displays a text bar with the specified title and text.

.PARAMETER txt
The text to display in the text bar.

.EXAMPLE
TextBar "Downloading tabs..."

.NOTES
Author: Zanzo
#>
function TextBarW($txt)
{
    write-host "[ " -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host $txt -ForegroundColor DarkRed -BackgroundColor Black -NoNewline
    write-host " ]" -ForegroundColor Red -BackgroundColor Black -NoNewline
}

<#
.SYNOPSIS
Display a text bar with a title and text.

.DESCRIPTION
This function displays a text bar with the specified title and text.

.PARAMETER title
The title to display in the text bar.

.PARAMETER txt
The text to display in the text bar.

.EXAMPLE
TextBarL "Downloading tabs..." "Metallica"

.NOTES
Author: Zanzo
#>
function TextBarL($title, $txt)
{
    TextBarW($title); write-host " $($txt)"
}

<#
.SYNOPSIS
Display a text log message.

.DESCRIPTION
This function displays a text log message with the specified text.

.PARAMETER txt
The text to display in the log message.

.EXAMPLE
TextLog "Downloading tabs..."

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
function TextLog($txt)
{
    TextBar("SongsterrGPDownloader"); write-host " $($txt)"
}

<#
.SYNOPSIS
Display a banner

.DESCRIPTION
This function displays a banner with the text "zRocksmith Utilities" in red.

.EXAMPLE
uiBanner

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
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

<#
.SYNOPSIS
Display text with a zRS prefix.

.DESCRIPTION
This function displays text with a zRS prefix.

.PARAMETER txt
The text to display.

.EXAMPLE
uiText "Downloading tabs..."

.NOTES
Author: Zanzo
#>
function uiText($txt)
{
    write-host ""
    write-host '[' -ForegroundColor Red -NoNewline -BackgroundColor Black
    write-host 'zRS' -ForegroundColor DarkRed -NoNewline -BackgroundColor Black
    write-host ']' -ForegroundColor Red -BackgroundColor Black -NoNewline
    write-host " $($txt)"
}

<#
.SYNOPSIS
Display a banner with text.

.DESCRIPTION
This function displays a banner with the specified text.

.PARAMETER txt
The text to display in the banner.

.EXAMPLE
uiBannerText "Hello, World!"

.NOTES
Author: Zanzo
#>
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

<#
.SYNOPSIS
Display a banner with text in a specified color.

.DESCRIPTION
This function displays a banner with the specified text in the specified color.

.PARAMETER txt
The text to display in the banner.

.PARAMETER color
The color of the text in the banner.

.EXAMPLE
uiBannerText "Hello, World!" "Green"

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
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

