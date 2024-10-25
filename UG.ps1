

#region Ultimate-Guitar Search Functions
########################################################
function Get-UGSearchData([string]$queryString)
{
    try {
        # Validate the input queryString
        if ([string]::IsNullOrWhiteSpace($queryString)) {
            throw [System.ArgumentException]::new("Query string cannot be null or empty.")
        }
        # Escape the input queryString
        $cleanQuery = [URI]::EscapeUriString($queryString)
        # Form the search url
        $url = "https://www.ultimate-guitar.com/search.php?title=$($cleanQuery)&page=1&type=500"
        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Extract the HTML content
        $htmlContent = $response.Content
        # Define the regex pattern to match the data-content attribute of the js-store div class
        $regex_pattern = '<div class="js-store" data-content="([^"]*)">'
        # Use the regex_pattern to find the JSON search data
        $matches = [regex]::Matches($htmlContent, $regex_pattern)

        if ($matches.Count -eq 0) {
            throw [System.Exception]::new("No JSON data found in the HTML content.")
        }

        # Extract the JSON data from the contents of the 'data-content' attribute
        foreach ($match in $matches) {
            $dataContent = $match.Groups[1].Value
            $results = $dataContent.Replace("&quot;", '"')
        }
        # Create an object from the extracted JSON data
        $obj = $results | ConvertFrom-Json
        # Return just the search results data from the JSON object
        return $obj.store.page.data
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

function Get-UGSearchJSON([string]$searchQuery)
{
    # Validate the input url
    if ([string]::IsNullOrWhiteSpace($searchQuery)) {
        throw [System.ArgumentException]::new("SearchQuery cannot be null or empty.")
    }
    # Encode the search Query for URL
    $encodedSearchQuery = [URI]::EscapeUriString($searchQuery)

    # Define the API endpoint
    $apiUrl = "https://api.ultimate-guitar.com/search.php?search_type=title&value=$($encodedSearchQuery)&type=500"

    # Perform the web request
    $response = Invoke-WebRequest -UseBasicParsing -Uri $apiUrl
    if($response.content -match '<div class="js-store" data-content="(.*)"></div>'){
        $data = "$($Matches[0].Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('&quot;', '"').Replace('&amp;', '&'))"
        return ConvertTo-Json($data)
    }else{
        write-host "ERROR: No 'js-store' data found for $($searchQuery)!" -ForegroundColor Red
        return $null
    }
}

function Check-UGHasProTab([string]$query, [switch]$Verbose)
{
    $ResObj = Get-UGSearchData "$($query)"

    if ($ResObj) {
        if ($Verbose) {
            Write-Host 'Guitar Pro tab for "' -NoNewline
            Write-Host "$($query)" -NoNewline -ForegroundColor Green
            Write-Host '" found on Ultimate-Guitar'
            Write-Host "Results Count: " -NoNewline
            Write-Host "$($ResObj.results_count)" -ForegroundColor Green
            $i = 0
            foreach ($res in $ResObj.results) {
                if ($res.type -eq "Pro") {
                    Write-Host "[$($i)] Tab URL: " -NoNewline
                    Write-Host "$($ResObj.results[$i].tab_url)" -ForegroundColor Green
                }
                $i++
            }
        }
        return $true
    } else {
        if ($Verbose) { Write-Host "No results found." -ForegroundColor Red }
        return $false
    }
}
#endregion


#region Ultimate-Guitar MetaData Functions
##################################################
# This gets the meta data for a specific tab by SongID, using UG's Pro MetaData API
function Get-UGProMetaData([int]$SongID)
{
    try {
        # Validate the input SongID
        if (!$SongID) {
            throw [System.ArgumentException]::new("SongID cannot be null or empty.")
        }
        # Form the UG MetaData API url
        $url = "https://api-web.ultimate-guitar.com/v1/tab/pro/meta?id=$($SongID)"
        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Create an object from the JSON meta data and return it
        return $response.content | ConvertFrom-Json
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# This function gets the 'js-store' data from a page on UG, and returns a JSON object of the data
function Get-UGMetaData([string]$url)
{
    $res = Invoke-WebRequest -Uri $url -UseBasicParsing
    if($res.content -match '<div class="js-store" data-content="(.*)"></div>'){
        $data = "$($Matches[0].Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('&quot;', '"').Replace('&amp;', '&'))"
        return ConvertFrom-Json($data)
    }else{
        write-host "ERROR: No 'js-store' data found!" -ForegroundColor Red
        return $null
    }
}

# This function gets the 'js-store' data from a page on UG, and returns a JSON object of the 'store.page.data' object
function Get-UGPageData([string]$url)
{
    $res = Invoke-WebRequest -UseBasicParsing -Uri $url #"https://www.ultimate-guitar.com/explore?order=date_desc&type[]=Official"
    if($res.content -match '<div class="js-store" data-content="(.*)"></div>'){
        $data = "$($Matches[0].Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('&quot;', '"').Replace('&amp;', '&'))"
        return (ConvertFrom-Json($data)).store.page.data
    }else{
        return write-host "ERROR: No 'js-store' data found!" -ForegroundColor Red
    }
}

# This is the same as the above function, but returns the raw JSON data instead of the 'store.page.data' object
function Get-UGPageJSON([string]$url)
{
    try {
        # Validate the input url
        if ([string]::IsNullOrWhiteSpace($url)) {
            throw [System.ArgumentException]::new("URL cannot be null or empty.")
        }

        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Extract the HTML content
        $htmlContent = $response.Content
        # Define the regex pattern to match the contents of the 'data-content' attribute of the 'js-store' div class
        $regex_pattern = '<div class="js-store" data-content="([^"]*)">'
        # Use the regex_pattern to find the JSON data
        $jsonData = [regex]::Matches($htmlContent, $regex_pattern)
        $jsonData
        if ($matches.Count -eq 0) {
            throw [System.Exception]::new("No JSON data found in the HTML content.")
        }

        # Extract the JSON data from the contents of the 'data-content' attribute
        foreach ($match in $matches) {
            $dataContent = $match.Groups[1].Value
            $results = $dataContent.Replace("&quot;", '"')
        }
        # Return the JSON data from the page
        return $results | ConvertFrom-Json
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
#endregion


#region Ultimate-Guitar Backing Tracks Functions
##########################################################
<#
.SYNOPSIS
Get-UGBackingTracksTabsList retrieves a list of all UG Tabs with Backing Tracks

.DESCRIPTION
This function retrieves a list of all UG Tabs with Backing Tracks, and saves the list to a text file.

.PARAMETER Verbose
Switch to display verbose output

.EXAMPLE
$TabsWithBackingTracks = Get-UGBackingTracksTabsList -Verbose

.NOTES
Author: Zanzo
Date: 2024-09-01
#>
function Get-UGBackingTracksTabList([switch]$Verbose)
{
    write-host "Retrieving list of all UG Tabs w/ Backing Tracks, this will take 2-5 minutes to complete..." -ForegroundColor Yellow
    $btData = Get-UGMetaData("https://www.ultimate-guitar.com/backing_track/")
    $btData.models
    
    [int]$btPageSize = $btData.pagination.pageSize
    [int]$btTotalPages = $btData.pagination.total
    [int]$btTotalCount = $btData.pagination.totalCount

    $retData = @()
    for($i -eq 0;$i -lt $btTotalPages;$i++){
        $btPageData = Get-UGMetaData("https://www.ultimate-guitar.com/backing_track/?page=$($i+1)")
        foreach($t in $btPageData.models){
            if($Verbose){write-host "[$($t.id)] $($t.artist_name) - $($t.song_name)`t$($t.url)"}
            $retData += "$($t.artist_name),$($t.song_name),$($t.id),$($t.url)`n"
        }
        if($Verbose){
            write-host "`t`t`t`t[Tabs: " -nonewline; write-host "$($retData.count)" -nonewline -ForegroundColor Cyan; write-host " of $($btTotalCount)] " -NoNewline
            write-host "[PAGE: " -nonewline; write-host "$($i+1)" -NoNewline -ForegroundColor Green; write-host "/" -nonewline; write-host "$($btTotalPages)" -nonewline -ForegroundColor Green; write-host "]"
        }
    }
    return $retData | out-file ".\UGBackingTracksTabsList.txt"
}

<#
.SYNOPSIS
Get-UGBackingTracks retrieves the name and audio dl url for each track from a UG Backing Tracks URL

.DESCRIPTION
This function retrieves the name and download url for each track from a UG Backing Tracks URL, and returns the url's to the audio for each track.

.PARAMETER backingTracksUrl
The URL of the UG Backing Tracks page to retrieve the backing tracks from.

.EXAMPLE
$BackingTracks = Get-UGBackingTracks "https://www.ultimate-guitar.com/backing_track/artist/artist_name/song/song_name"

.NOTES
Author: Zanzo
Date: 2024-09-01
#>
function Get-UGBackingTracks([string]$backingTracksUrl)
{
    $r = Get-UGMetaData($backingTracksUrl)
    # get the url to the audio for each track
    $backingTracks = $r.viewer.backing_track
    $newTracks,$newTrack = @()
    foreach($track in $backingTracks.content_urls){
        $newTracks += "$($track.name)`t$($track.content_urls.normal)"
        write-host "$($track.name)`t$($track.content_urls.normal)"
    }
    return $backingTracks.content_urls
}

<#
.SYNOPSIS
Download-UGBackingTracks downloads the backing tracks from a UG Backing Tracks URL

.DESCRIPTION
This function downloads the backing tracks from a UG Backing Tracks URL and saves them to the 'backing_tracks' directory.

.PARAMETER BackingTracksUrl
The URL of the UG Backing Tracks page to retrieve the backing tracks from.

.EXAMPLE
Download-UGBackingTracks "https://www.ultimate-guitar.com/backing_track/artist/artist_name/song/song_name"

.NOTES
Author: Zanzo
Date: 2024-09-01
#>
function Download-UGBackingTracks([string]$BackingTracksUrl)
{
    $r = Get-UGMetaData($BackingTracksUrl)
    if ($r -ne $null -and $r.viewer -ne $null) {
        $tabInfo = $r.viewer.backing_track
        if(!(Test-Path ".\backing_tracks\$($tabInfo.artist) - $($tabInfo.song)")){
            mkdir ".\backing_tracks\$($tabInfo.artist) - $($tabInfo.song)"
        }
        $backingTracks = $r.viewer.backing_track.content_urls
        $newTracks = @()
        foreach($track in $backingTracks){
            $newTrack = [PSCustomObject]@{
                Name  = $track.name
                Audio = $track.content_urls.normal
            }
            $newTracks += $newTrack
        }
        $newTracks | Format-Table -AutoSize
        foreach($trk in $newTracks){
            write-host "Saving $($trk.name)..."
            Invoke-WebRequest -UseBasicParsing -Uri $trk.Audio -OutFile ".\backing_tracks\$($tabInfo.artist) - $($tabInfo.song)\$($trk.Name).mp3"
        }
    }else{Write-Host "ERROR: No viewer data found!" -ForegroundColor Red}
}
#endregion