function Get-TunebatData([string]$SearchQuery, [switch]$extDetails, [switch]$Verbose)
{
    try {
        # Validate the search query
        if ([string]::IsNullOrWhiteSpace($SearchQuery)) {
            throw [System.ArgumentException]::new("Search Query cannot be null or empty.")
        }
        # URL encode the search query for the API request
		$encodedQuery = [URI]::EscapeUriString($SearchQuery)
        
		# Define the API endpoint with the encoded search query
		$apiUrl = "https://api.tunebat.com/api/tracks/search?term=$($encodedQuery)&page=1"

		# Send the HTTP GET request to the API endpoint and get the response
		$response = Invoke-RestMethod -UseBasicParsing -Uri "$($apiUrl)"
        #$response = Invoke-WebRequest -UseBasicParsing -Uri "$($apiUrl)"

		# Convert the response into a JSON object
		$json = ConvertFrom-Json $response.Content

		# Verify that the response contains results
		if ($json.data.totalCount -gt 0) {
			# Get the top Tunebat search result
			$topResult = $json.data.items[0]

            # Create a custom object from the extracted data
            $SongDetails = [PSCustomObject]@{
                TunebatID = $topResult.id #$id
                SongName = $topResult.n
                ArtistName = $artistName = $topResult.as[0]
                Key = $topResult.k
                KeyValue = $topResult.kv
                Tempo = $topResult.b
                Duration = $topResult.d
                Album = $topResult.an
                Label = $topResult.l
                ReleaseDate = $topResult.rd
                CoverImage = $topResult.ci[0].iu
                Popularity = $topResult.p
                Camelot = $topResult.c
                Acousticness = $topResult.ac
                Danceability = $topResult.da
                Energy = $topResult.e
                Happiness = $topResult.h
                Instrumentalness = $topResult.i
                Liveness = $topResult.li
                Loudness = $topResult.lo
                Speechiness = $topResult.s
                isExplicit = $topResult.ie
                isSingle = $topResult.is
                DataURL = "https://api.tunebat.com/api/tracks?trackid=$($topResult.id)"
            }

            if($Verbose){
                # Display the song details
                Write-Host "`n---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Tunebat Search Result for " -nonewline -BackgroundColor Black; Write-Host $SearchQuery -ForegroundColor Green -BackgroundColor Black
                write-host "---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Title:`t" -nonewline; Write-Host "$($SongDetails.SongName)" -foregroundcolor Green
                Write-Host "Artist:`t" -nonewline; Write-Host "$($SongDetails.artistName)" -foregroundcolor Green
                if($extDetails){ Write-Host "Album:`t" -nonewline; Write-Host "$($SongDetails.album)" -foregroundcolor Green -NoNewline; Write-Host " (" -nonewline; Write-Host "$($SongDetails.releaseDate)" -foregroundcolor DarkGreen -NoNewline; Write-Host ")" }
                Write-Host "Key:`t" -nonewline; Write-Host "$($SongDetails.key)" -foregroundcolor Green -NoNewline; write-host " (" -nonewline; write-host "$($SongDetails.key.Replace(' Minor','m').Replace(' Major',''))" -ForegroundColor Green -NoNewline; write-host ") $($SongDetails.keyValue)"
                Write-Host "Tempo:`t" -nonewline; Write-Host "$($SongDetails.tempo)" -foregroundcolor Green 
                if($extDetails){ Write-Host "Popularity:`t" -nonewline; Write-Host "$($SongDetails.popularity)" -foregroundcolor Green; Write-Host "Album Art:`t" -nonewline; Write-Host "$($SongDetails.coverImage)" -foregroundcolor Green }
            }
            return $SongDetails
		}else{
            if($Verbose){ Write-Host "No results found for the search query: " -nonewline; Write-Host $SearchQuery -foregroundcolor Red }
            return $null
		}
    }
    catch { 
        Write-Error "An error occurred: $($_)"
        return $null
    }
}

$ss = Get-TunebatData -SearchQuery "Bad Omens - Just Pretend" #-Verbose -extDetails
$ss