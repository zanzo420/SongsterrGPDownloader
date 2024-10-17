$url = 'https://youtu.be/ZwNXoUsvkNc'



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

function Get-YoutubeVideoId([string]$url){
    return $videoId = [regex]::Match($url, "(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)(?:\&.*)|(?>https:\/\/www\.youtube\.com\/watch\?v\=)(?<VideoID>.*)|(?>https\:\/\/youtu\.be\/)(.*)").Groups[1].Value
}


$res = Get-YoutubeVideoInfo("https://youtu.be/uMVoUHi0J1Q")
$temp = Generate-SongsterrAITab -title $res.Title -artist $res.Artist -videoId $res.VideoId
if($temp.success){
    write-host "[SongsterrAI] Successfully started generating Guitar Pro tab for '$($res.Artist) - $($res.Title)' (TranscriptionID: $($temp.transcriptionId))"$temp.transcriptionId
}else{
    write-host "[SongsterrAI] Failed to start Guitar Pro tab generation" -ForegroundColor Red
}