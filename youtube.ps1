# YouTube API functions, video information, video ID, and Artist/Title extraction


#region YouTube Functions
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

    # Remove " - YouTube" from the end of the title
    $title = $title -replace " - YouTube$", ""

    return $title
}

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
function Extract-ArtistAndSongFromTitle([string]$videoTitle)
{
    # Define common patterns
    $patterns = @(
        '^(?<artist>.+?)\s*-\s*(?<title>.+)$',  # Artist - Title
        '^(?<title>.+?)\s*by\s*(?<artist>.+)$', # Title by Artist
        '^(?<artist>.+?)\s*:\s*(?<title>.+)$',  # Artist: Title
        '^(?<title>.+?)\s*\((?<artist>.+)\)$'   # Title (Artist)
    )

    foreach ($pattern in $patterns) {
        if ($videoTitle -match $pattern) {
            return @{
                Artist = $matches['artist']
                Title  = $matches['title'].replace('(Lyrics)','').replace('🎵','').trim()
            }
        }
    }

    # Fallback: Split by common delimiters and assume first part is artist, second is title
    $delimiters = @(' - ', ' by ', ': ', ' (', ')')
    foreach ($delimiter in $delimiters) {
        if ($videoTitle -contains $delimiter) {
            $parts = $videoTitle -split [regex]::Escape($delimiter)
            if ($parts.Count -ge 2) {
                return @{
                    Artist = $parts[0].Trim()
                    Title  = $parts[1].replace('(Lyrics)','').replace('🎵','').Trim()
                }
            }
        }
    }

    # If no pattern matches, return the original title as the song title
    return @{
        Artist = "Unknown"
        Title  = $videoTitle.replace('(Lyrics)','').replace('🎵','').trim()
    }
}

<#
.SYNOPSIS
Gets the video info from a YouTube video URL.

.DESCRIPTION
This function takes a YouTube video URL as input and extracts the video info from it.

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
    $result = Extract-ArtistAndSongFromTitle -videoTitle "$($videoTitle)"
    return @{
        Artist = $result.Artist
        Title = $result.Title
        VideoID = Get-YouTubeVideoID($url)
        VideoTitle = $videoTitle
        Url = $url
    }
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
    $videoId = [regex]::Match($url, "(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)(?:\&.*)|(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)|(?>https\:\/\/youtu\.be\/)(.*)").Groups[1].Value
    return $videoId
}
#endregion