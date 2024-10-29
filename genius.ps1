# Genius.com Lyrics Search Functions
#API Search query URL: https://genius.com/api/search/multi?q=
#HTTPS Search query URL: https://genius.com/search?q=

function Search-GenuisLyrics {
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