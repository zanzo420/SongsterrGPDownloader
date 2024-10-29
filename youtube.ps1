# YouTube API functions, video information / video ID / Artist and Title extraction
$Script:youtube_regex = "^(?:https?:)?(?:\/\/)?(?:youtu\.be\/|(?:www\.|m\.)?youtube\.com\/(?:watch|v|embed)(?:\.php)?(?:\?.*v=|\/))([a-zA-Z0-9\_-]{7,15})(?:[\?&][a-zA-Z0-9\_-]+=[a-zA-Z0-9\_-]+)*(?:[&\/\#].*)?$"
$Local:vID_regex = "(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)(?:\&.*)|(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)|(?>https\:\/\/youtu\.be\/)(.*)"

#region YouTube Functions
function Test-YouTubeURL([string]$url){
    if($url -match $youtube_regex){ return $true }
    else{return $false}
}

<#
.SYNOPSIS
Gets the video title from a YouTube video URL.

.DESCRIPTION
This function takes a YouTube video URL as input and extracts the video title from the HTML content of the video page.

.PARAMETER url
The URL of the YouTube video.

.EXAMPLE
Get-YouTubeVideoTitle -url "https://youtu.be/ZwNXoUsvkNc"

.NOTES
Author: Zanzo
Date: 2024-10-07
#>
function Get-YouTubeVideoTitle([string]$url)
{
    # Send a web request to the YouTube video page
    $response = Invoke-WebRequest -Uri $url
    # Extract the title from the HTML content
    $title = ($response.ParsedHtml.getElementsByTagName("title") | Select-Object -First 1).innerText
    # Remove " - YouTube" from the end of the title and return the result
    return $title -replace " - YouTube$", ""
}

<#
.SYNOPSIS
Gets the video ID from a YouTube video URL.

.DESCRIPTION
This function takes a YouTube video URL as input and extracts the video ID from it.

.PARAMETER url
The URL of the YouTube video.

.EXAMPLE
Get-YouTubeVideoID -url "https://youtu.be/ZwNXoUsvkNc"

.NOTES
Author: Zanzo
Date: 2024-10-07
#>
function Get-YoutubeVideoId([string]$url){
    $videoId = [regex]::Match($url, $youtube_regex).Groups[1].Value
    return $videoId
}

<#
.SYNOPSIS
Gets the video ID from a YouTube video URL.

.DESCRIPTION
This function takes a YouTube video URL as input and extracts the video ID from it.

.PARAMETER url
The URL of the YouTube video.

.EXAMPLE
Get-YouTubeVideoID -url "https://youtu.be/ZwNXoUsvkNc"

.NOTES
Author: Zanzo
Date: 2024-10-07
#>
function Get-VideoIDFromUrl([string]$url){
    $videoId = [regex]::Match($url, $vID_regex).Groups[1].Value
    return $videoId
}

<#
.SYNOPSIS
Gets the video info from a YouTube video URL.

.DESCRIPTION
This function takes a YouTube video URL as input and extracts the video info from it. It uses the Get-YouTubeVideoTitle, Get-ArtistAndSongFromTitle, and Get-YouTubeVideoID functions to get the artist, song title, video title, and video id.

.PARAMETER url
The URL of the YouTube video.

.EXAMPLE
Get-YouTubeVideoInfo -url "https://youtu.be/ZwNXoUsvkNc"

.NOTES
Author: Zanzo
Date: 2024-10-07
#>
function Get-YouTubeVideoInfo([string]$url)
{
    $videoTitle = Get-YouTubeVideoTitle($url)
    $result = Get-ArtistAndSongFromTitle -videoTitle "$($videoTitle)"
    return @{
        Artist = $result.Artist
        Title = $result.Title
        VideoID = Get-YouTubeVideoID($url)
        VideoTitle = $videoTitle
        Url = $url
    }
}
#endregion


#region Misc Functions
<#
.SYNOPSIS
Extracts the artist and song title from a YouTube video title.

.DESCRIPTION
This function takes a YouTube video title as input and attempts to extract the artist and song title from it. It uses a series of regular expressions to match common patterns in video titles, such as "Artist - Title" or "Title by Artist". If no pattern matches, it splits the title by common delimiters like " - " or " by " and assumes the first part is the artist and the second part is the song title. If no delimiters are found, it returns the original title as the song title and sets the artist to "Unknown".

.PARAMETER videoTitle
The title of the YouTube video.

.EXAMPLE
Extract-ArtistAndSongFromTitle -videoTitle "Ed Sheeran - Shape of You (Lyrics)"

.NOTES
Author: Zanzo
Date: 2024-10-07
#>
function Get-ArtistAndSongFromTitle([string]$videoTitle)
{
    # Define common patterns
    $patterns = @(
        '^(?<artist>.+?)\s*-\s*(?<title>.+)$',  # Artist - Title
        '^(?<title>.+?)\s*by\s*(?<artist>.+)$', # Title by Artist
        '^(?<artist>.+?)\s*:\s*(?<title>.+)$',  # Artist: Title
        '^(?<title>.+?)\s*\((?<artist>.+)\)$'   # Title (Artist)
    )
    # Try to match the title against the patterns
    foreach ($pattern in $patterns) {
        if ($videoTitle -match $pattern) {
            return @{
                Artist = ($matches['artist']).replace('(Lyrics)','').replace('🎵','').trim()
                Title  = ($matches['title']).replace('(Lyrics)','').replace('🎵','').trim()
            }
        }
    }
    # Fallback: Split by common delimiters and assume first part is artist, second is title
    $delimiters = @(' - ', ' by ', ': ', ' (', ')', ' -', '-', '- ')
    foreach ($delimiter in $delimiters) {
        if ($videoTitle -contains $delimiter) {
            $parts = $videoTitle -split [regex]::Escape($delimiter)
            if ($parts.Count -ge 2) {
                return @{
                    Artist = $parts[0].replace('(Lyrics)','').replace('🎵','').Trim()
                    Title  = $parts[1].replace('(Lyrics)','').replace('🎵','').Trim()
                }
            }
        }
    }
    # If none of the patterns above matches, return the original title as the song title
    return @{
        Artist = "Unknown"
        Title  = $videoTitle.replace('(Lyrics)','').replace('🎵','').trim()
    }
}
#endregion


#region YouTube-to-MP3 Functions
#################################################
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
function Get-YouTubeMP3([string]$vID, [switch]$OpenInBrowser)
{
    if($OpenInBrowser){ Start-Process "https://y2hub.cc/enesto/download?src=query&url=$($vID)" }
    return "https://y2hub.cc/enesto/download?src=query&url=$($vID)"
}
#endregion