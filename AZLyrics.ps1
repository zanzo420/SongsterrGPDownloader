# AZLyrics.com Lyrics Scraper, Searcher, and Artist Song List Getter

#region AZLyrics Lyrics Functions
function Get-AZLyrics {
    param (
        [string]$Artist,
        [string]$Song
    )

    $url = "https://www.azlyrics.com/lyrics/$($Artist)/$($Song).html"
    $html = Invoke-WebRequest -Uri $url
    $lyrics = $html.ParsedHtml.getElementsByTagName("div") | Where-Object { $_.className -eq "ringtone" } | Select-Object -ExpandProperty innerText
    $lyrics
}

<#
.SYNOPSIS
Get lyrics for a song from AZLyrics.com

.DESCRIPTION
This function retrieves the lyrics for a given song from AZLyrics.com. It takes the artist and song names as input parameters and returns the lyrics as a string.

.PARAMETER Artist
The name of the artist

.PARAMETER Song
The name of the song

.EXAMPLE
Get-AZLyricsData -Artist "eminem" -Song "lose yourself"

.NOTES
Author: Zanzo
Date: 2024-10-06
#>
function Get-AZLyricsData([string]$Artist, [string]$Song) {
    # Convert the artist and song names to lowercase and remove spaces
    $artist = ($Artist -replace " ", "").ToLower()
    $title = ($Song -replace " ", "").ToLower()
    # Define the URL of the AZLyrics song page
    $url = "https://www.azlyrics.com/lyrics/$($artist)/$($title).html"
    # Send a GET request to the URL
    $response = Invoke-WebRequest -Uri $url
    # Parse the HTML content
    $htmlContent = $response.Content
    # Use regex to extract the lyrics
    $lyricsPattern = '<div>.*?<!-- Usage of azlyrics.com content.*?-->(.*?)</div>'
    $lyricsMatches = [regex]::Matches($htmlContent, $lyricsPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Extract and clean the lyrics text
    $lyrics = $lyricsMatches[0].Groups[1].Value -replace '<.*?>', '' -replace '\n', "`n"
    # Output the lyrics
    write-host $lyrics -ForegroundColor Green
    return $lyrics
}

<#
.SYNOPSIS
Search for lyrics on AZLyrics.com

.DESCRIPTION
This function searches for lyrics on AZLyrics.com based on a given query. It takes the query as an input parameter and returns a list of search results.

.PARAMETER Query
The search query

.EXAMPLE
Search-AZLyrics -Query "eminem lose yourself"

.NOTES
Author: Zanzo
Date: 2024-10-06
#>
function Search-AZLyrics([string]$Query) {
    # Define the search URL
    $url = "https://search.azlyrics.com/search.php?q=$($Query)"
    # Send a GET request to the search URL
    $response = Invoke-WebRequest -Uri $url
    # Parse the HTML content
    $htmlContent = $response.Content
    # Use regex to extract the search results
    $resultsPattern = '<a href="https://www.azlyrics.com/lyrics/.*?">(.*?)</a>'
    $resultsMatches = [regex]::Matches($htmlContent, $resultsPattern)
    # Output the search results
    foreach ($match in $resultsMatches) {
        Write-Output $match.Groups[1].Value
    }
    return $resultsMatches
}
#endregion

#region AZLyrics Artist Functions
<#
.SYNOPSIS
Get a list of songs by an artist from AZLyrics.com

.DESCRIPTION
This function retrieves a list of songs by a given artist from AZLyrics.com. It takes the artist name as an input parameter and returns a list of the artist's songs.

.PARAMETER Artist
The name of the artist

.EXAMPLE
Get-AZLyricsArtistSongs -Artist "eminem"

.NOTES
Author: Zanzo
Date: 2024-10-06
#>
function Get-AZLyricsArtistSongs([string]$Artist) {
    $cArtist = $Artist.ToLower().Replace(" ", "")
    # Define the artist page URL
    $url = "https://www.azlyrics.com/$($Artist[0])/$($cArtist).html"
    # Send a GET request to the artist page URL
    $response = Invoke-WebRequest -Uri $url
    # Parse the HTML content
    $htmlContent = $response.Content
    # Use regex to extract the artist's songs
    $songsPattern = '<a href="https://www.azlyrics.com/lyrics/.*?">(.*?)</a>'
    $songsMatches = [regex]::Matches($htmlContent, $songsPattern)
    # Output the artist's songs
    foreach ($match in $songsMatches) {
        Write-Output $match.Groups[1].Value
    }
    return $songsMatches
}
#endregion