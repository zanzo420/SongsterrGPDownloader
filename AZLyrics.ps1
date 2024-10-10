# Define the URL of the AZLyrics song page
$url = "https://www.azlyrics.com/lyrics/fallinginreverse/zombified.html"

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
Write-Output $lyrics