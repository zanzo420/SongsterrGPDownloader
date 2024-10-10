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
        VideoTitle = $videoTitl
        Url = $url
    }
}

function Generate-SongsterrAITab($title, $artist, $videoId)
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
  -Body "{`"title`":`"$($title)`",`"artist`":`"$($artist)`",`"videoId`":`"$($videoId)`"}"

  return $response.Content
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