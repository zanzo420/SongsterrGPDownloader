# Genius.com Lyrics Search Functions
#API Search query URL: https://genius.com/api/search/multi?q=
#HTTPS Search query URL: https://genius.com/search?q=

#### GLOBAL VARIABLES ####
$GENIUS_ACCESS_TOKEN = $env:GENIUS_ACCESS_TOKEN
$LYRICS_CONTAINER_CLASS = "Lyrics__Container-sc-1ynbvzw-1 kUgSbL"   # last updated 2024-10-29

#region Misc Utility Functions
<#
.SYNOPSIS
Get the class name of the lyrics container from a Genius.com song lyrics page URL.

.DESCRIPTION
This function retrieves the class name of the lyrics container from a Genius.com song lyrics page URL. It takes the URL to a song lyrics page on Genius.com as input and returns the class name of the lyrics container.

.PARAMETER url
The URL of the song lyrics page on Genius.com.

.EXAMPLE
$LYRICS_CONTAINER_CLASS = GetlyricsClassName("https://genius.com/Bad-omens-nowhere-to-go-lyrics")

.NOTES
Author: Zanzo
Date: 2024-10-30
#>
function Get-LyricsClassName($url){
    #old_regex = "(?<LyricsClassName>LyricsHeader__Container-[a-zA-Z0-9-]* ([a-zA-Z0-9]+)?)"
    $response = Invoke-WebRequest -Uri $url
    $divElements = $response.parsedHTML.getElementsByTagName("DIV")
    foreach($div in $divElements){
        if($div.className -match "Lyrics__Container.*"){ return $div.className }
    }
}

<#
.SYNOPSIS
Updates the LYRICS_CONTAINER_CLASS global variable with the current class name of the lyrics container from a current Genius.com lyrics page.

.DESCRIPTION
This function updates the LYRICS_CONTAINER_CLASS global variable with the current class name of the lyrics container from a Genius.com song lyrics page URL.

.EXAMPLE
Update-LyricsClassName

.NOTES
Author: Zanzo
Date: 2024-10-31
#>
function Update-LyricsClassName(){
    $lyricsClassName = Get-LyricsClassName("https://genius.com/Bad-omens-nowhere-to-go-lyrics")
    if($lyricsClassName){
        $global:LYRICS_CONTAINER_CLASS = $lyricsClassName
        Write-Host "Lyrics container class name updated to: $($global:LYRICS_CONTAINER_CLASS)"
    }else{
        Write-Error "Failed to update lyrics container class name. Make sure the URL is valid."
    }
}
#endregion

function Search-GeniusLyrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SearchQuery
    )

    # Replace spaces with %20 for URL encoding
    $EncodedQuery = [URI]::EscapeUriString($SearchQuery)
    # Define the API endpoint with the search query
    $ApiUrl = "https://genius.com/api/search/multi?q=$($EncodedQuery)"
    # Send the HTTP GET request to the API endpoint
    $Response = Invoke-WebRequest -UseBasicParsing -Uri "$($ApiUrl)" `
        -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0" `
        -Headers @{
            "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8"
            "Accept-Language" = "en-US,en;q=0.5"
            "Accept-Encoding" = "gzip, deflate, br, zstd"
            "Upgrade-Insecure-Requests" = "1"
            "Priority" = "u=0, i"
            "Origin" = "https://Genius.com"
        }
    $Json = ConvertFrom-Json $Response.Content

    # Check the status from the API response for code 200, which indicates success (aka results found)
    if ($Json.meta.status -eq 200) {
        # Get the top search result
        $TopResult = $Json.response.sections[0].hits[0].result

        # Extract the song details
        $SongDetails = [PSCustomObject]@{
            GeniusId      = $TopResult.id
            FullTitle     = $TopResult.full_title
            SongName      = $TopResult.title
            ArtistName    = $TopResult.artist_names
            Url           = $TopResult.url
            AlbumImageURL = $TopResult.header_image_url
            ReleaseDate   = $TopResult.release_date_for_display
        }

        # Display the song details
        Write-Host "`n---------------------------------------------------" -ForegroundColor Gray
        Write-Host "Genius Lyrics Search Result for '" -nonewline; Write-Host $SongDetails.FullTitle -ForegroundColor Green -NoNewline
        write-host "'`n---------------------------------------------------" -ForegroundColor Gray
        Write-Host "Title:`t" -nonewline; Write-Host "$($SongDetails.SongName)" -foregroundcolor Green
        Write-Host "Artist:`t" -nonewline; Write-Host "$($SongDetails.ArtistName)" -foregroundcolor Green
        write-Host "Released:`t" -NoNewline; write-host "$($SongDetails.ReleaseDate)" -ForegroundColor Green
        write-host "GeniusID:`t" -NoNewline; write-host "$($SongDetails.GeniusId)" -ForegroundColor Green
        Write-Host "Lyrics URL:`t" -nonewline; Write-Host "$($SongDetails.Url)" -foregroundcolor Green
        Write-Host "Album Art:`t" -nonewline; Write-Host "$($SongDetails.AlbumImageURL)" -foregroundcolor Green

        return $SongDetails
    }else{
        Write-Host "No results found for the search query: " -nonewline; Write-Host $SearchQuery -foregroundcolor Red
        return $null
    }
}

<#
.SYNOPSIS
Get lyrics for a song from Genius.com using the Genius API.

.DESCRIPTION
This function retrieves the lyrics for a song from Genius.com using the Genius API. It takes the artist name and song title as input parameters and returns the lyrics as a string.

.PARAMETER artist
The name of the artist of the song.

.PARAMETER songTitle
The title of the song.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-GeniusLyrics -artist "Eminem" -songTitle "Lose Yourself"

.NOTES
Author: Zanzo
Date: 2024-10-09
#>
function Search-GeniusLyrics([string]$artist, [string]$songTitle, [switch]$Verbose) {
    # Encode the artist and song title for the API request
    $query = [System.Web.HttpUtility]::UrlEncode("$($artist) - $($songTitle)")
    # Genius API URL for search
    $searchUrl = "https://api.genius.com/search?q=$($query)"
    $headers = @{ Authorization = "Bearer $($GENIUS_ACCESS_TOKEN)" }

    # Send request to Genius API to search for the song
    try { 
        $response = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
    }catch{ 
        Write-Error "Error fetching song data from Genius API. Make sure your 'GENIUS_ACCESS_TOKEN' is correct."
        return
    }
    # Check if the search returned any results, if no results found, return
    if ($response.response.hits.Count -eq 0) {
        if($Verbose){ Write-Host "No results found for $($artist) - $($songTitle)"}
        return
    }
    # Extract the URL from the first search result
    $songUrl = $response.response.hits[0].result.url
    # Fetch the lyrics from the song's lyrics page URL
    if($Verbose){ Write-Host "Fetching lyrics from $($songUrl) "}
    try {
        $html = Invoke-WebRequest -Uri $songUrl
        $lyrics = ($html.ParsedHtml.getElementsByClassName("$($LYRICS_CONTAINER_CLASS)") | ForEach-Object { $_.innerText }) -join "`n`n`n`n"
    } catch {
        Write-Error "Error fetching or parsing lyrics from $($songUrl)"
        return
    }
    # Display the lyrics if Verbose mode is enabled
    if($Verbose){ Write-Host "`n--- Lyrics for '$($songTitle)' by '$($artist)' ---`n`n$($lyrics)" }
    # Return the lyrics as a string
    return $lyrics
}

<#
.SYNOPSIS
Get lyrics for a song from Genius.com using the song URL.

.DESCRIPTION
This function retrieves the lyrics for a song from Genius.com using the song URL. It takes the URL of the song as input and returns the lyrics as a string.

.PARAMETER url
The URL of the song on Genius.com.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-GeniusLyrics -url "https://genius.com/Eminem-lose-yourself-lyrics"

.NOTES
Author: Zanzo
Date: 2024-10-09
#>
function Get-GeniusLyrics([string]$url, [switch]$Verbose) {
    # Verify that the URL is a valid Genius lyrics page URL
    if($url -like "https://genius.com/*-lyrics") {
        $songUrl = $url
    }else{
        Write-Error "Invalid URL. Please provide a valid lyrics page URL.`n(note: a valid lyrics page URL should always end with '-lyrics')"
        return
    }
    $songUrl = $url
    if($Verbose){ Write-Host "[Genius] Fetching lyrics from $($songUrl) "}
    # Fetch the lyrics from the song's URL
    try {
        $html = Invoke-WebRequest -Uri $songUrl
        $lyrics = ($html.ParsedHtml.getElementsByClassName("$($LYRICS_CONTAINER_CLASS)") | ForEach-Object { $_.innerText }) -join "`n"
    } catch {
        Write-Error "[Genius] Error fetching or parsing lyrics from $($songUrl)"
        return
    }
    # Display the lyrics if Verbose mode is enabled
    if($Verbose){ Write-Host "`n[Genius] --- Lyrics for '$($songTitle)' by '$($artist)' ---`n"; Write-Host "$($lyrics)" }
    # Return the lyrics as a string
    return $lyrics
}