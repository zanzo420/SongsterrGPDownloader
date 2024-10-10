# Define the search query
$searchQuery = "Bad Omens - Just Pretend"

# Replace spaces with %20 for URL encoding
$encodedQuery = [URI]::EscapeUriString($searchQuery)

# Define the API endpoint with the search query
$apiUrl = "https://genius.com/api/search/multi?q=$($encodedQuery)"

# Send the HTTP GET request to the API endpoint
$response = Invoke-WebRequest -UseBasicParsing -Uri "$($apiUrl)" `
-UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0" `
-Headers @{
"Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8"
  "Accept-Language" = "en-US,en;q=0.5"
  "Accept-Encoding" = "gzip, deflate, br, zstd"
  "Upgrade-Insecure-Requests" = "1"
  "Priority" = "u=0, i"
  "Origin" = "https://Genius.com"
}
$json = ConvertFrom-Json $response.Content

# Check if the response contains results
if ($json.meta.status -eq 200) {
    # Get the top search result
    $topResult = $json.response.sections[0].hits[0].result
    #$topResult | out-file ".\script.txt" -force

    # Extract the song details
    $geniusId = $topResult.id
    $fullTitle = $topResult.full_title
    $songName = $topResult.title
    $artistName = $topResult.artist_names
    $url = $topResult.url
    $albumImageURL = $topResult.header_image_url
    $releaseDate = $topResult.release_date_for_display

    # Display the song details
    Write-Host "`n---------------------------------------------------" -ForegroundColor Gray
    Write-Host "Genius Lyrics Search Result for '" -nonewline; Write-Host $fullTitle -ForegroundColor Green -NoNewline; write-host "'`n---------------------------------------------------" -ForegroundColor Gray
    
    Write-Host "Title:   `t" -nonewline; Write-Host "$($songName)" -foregroundcolor Green
    Write-Host "Artist: `t" -nonewline; Write-Host "$($artistName)" -foregroundcolor Green
    write-Host "Released:`t" -NoNewline; write-host "$($releaseDate)" -ForegroundColor Green
    write-host "GeniusID: `t" -NoNewline; write-host "$($geniusId)" -ForegroundColor Green
    Write-Host "Lyrics URL:`t" -nonewline; Write-Host "$($url)" -foregroundcolor Green
    Write-Host "Album Art:`t" -nonewline; Write-Host "$($albumImageURL)" -foregroundcolor Green 
} else {
    Write-Host "No results found for the search query: " -nonewline; Write-Host $searchQuery -foregroundcolor Red
}