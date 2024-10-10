function Get-TunebatData([string]$searchQuery, [switch]$extDetails, [switch]$Verbose)
{
    try {
        # Validate the search query
        if ([string]::IsNullOrWhiteSpace($searchQuery)) {
            throw [System.ArgumentException]::new("Search Query cannot be null or empty.")
        }
        # URL encode the search query for the API request
		$encodedQuery = [URI]::EscapeUriString($searchQuery)
		
		# Define the API endpoint with the encoded search query
		$apiUrl = "https://api.tunebat.com/api/tracks/search?term=$($encodedQuery)&page=1"
		
		# Send the HTTP GET request to the API endpoint and get the response
		$response = Invoke-WebRequest -UseBasicParsing -Uri "$($apiUrl)" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0" `
		-Headers @{
		"Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8"
		"Accept-Language" = "en-US,en;q=0.5"
		"Accept-Encoding" = "gzip, deflate, br, zstd"
		"Upgrade-Insecure-Requests" = "1"
		"Priority" = "u=0, i"
		"Origin" = "https://tunebat.com"
		}

		# Convert the response into a JSON object
		$json = ConvertFrom-Json $response.Content
		
		# Check if the response contains results
		if ($json.data.totalCount -gt 0) {
			# Get the top search result
			$topResult = $json.data.items[0]
			#$topResult | out-file ".\script.txt" -force
		
			# Extract the song details
			$id = $topResult.id
            $songName = $topResult.n
			$artistName = $topResult.as[0]
			$key = $topResult.k
			$tempo = $topResult.b
            $duration = $topResult.d
			# Extract extra song details
            $album = $topResult.an
            $label = $topResult.l
			$releaseDate = $topResult.rd
			$coverImage = $topResult.ci[0].iu
			$popularity = $topResult.p
            # Extract full song details
            $keyValue = $topResult.kv
            $camelot = $topResult.c
            $acousticness = $topResult.ac
            $danceability = $topResult.da
            $energy = $topResult.e
            $happiness = $topResult.h
            $instrumentalness = $topResult.i
            $liveness = $topResult.li
            $loudness = $topResult.lo
            $speechiness = $topResult.s
            $isExplicit = $topResult.ie
            $isSingle = $topResult.is

            # Create a custom object from the extracted data
            $songDetails = [PSCustomObject]@{
                TunebatID = $id
                SongName = $songName
                ArtistName = $artistName
                Key = $key
                KeyValue = $keyValue
                Tempo = $tempo
                Duration = $duration
                Album = $album
                Label = $label
                ReleaseDate = $releaseDate
                CoverImage = $coverImage
                Popularity = $popularity
                Camelot = $camelot
                Acousticness = $acousticness
                Danceability = $danceability
                Energy = $energy
                Happiness = $happiness
                Instrumentalness = $instrumentalness
                Liveness = $liveness
                Loudness = $loudness
                Speechiness = $speechiness
                isExplicit = $isExplicit
                isSingle = $isSingle
                DataURL = "https://api.tunebat.com/api/tracks?trackid=$($id)"
            }
            if($Verbose){
                # Display the song details
                Write-Host "`n---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Tunebat Search Result for '" -nonewline -BackgroundColor Black; Write-Host $searchQuery -ForegroundColor Green -NoNewline -BackgroundColor Black
                write-host "'`n---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Title:`t" -nonewline; Write-Host "$($songName)" -foregroundcolor Green
                Write-Host "Artist:`t" -nonewline; Write-Host "$($artistName)" -foregroundcolor Green
                if($extDetails){ 
                    Write-Host "Album:`t" -nonewline; Write-Host "$($album)" -foregroundcolor Green -NoNewline; Write-Host " (" -nonewline; Write-Host "$($releaseDate)" -foregroundcolor DarkGreen -NoNewline; Write-Host ")"}
                Write-Host "Key:`t" -nonewline; Write-Host "$($key)" -foregroundcolor Green -NoNewline; write-host " (" -nonewline; write-host "$($key.Replace(' Minor','m').Replace(' Major',''))" -ForegroundColor Green -NoNewline; write-host ") $($keyValue)"
                Write-Host "Tempo:`t" -nonewline; Write-Host "$($tempo)" -foregroundcolor Green 
                if($extDetails){
                    Write-Host "Popularity:`t" -nonewline; Write-Host "$($popularity)" -foregroundcolor Green
                    Write-Host "Album Art:`t" -nonewline; Write-Host "$($coverImage)" -foregroundcolor Green}
            }
            return $songDetails
		} else {
            if($Verbose){ Write-Host "No results found for the search query: " -nonewline; Write-Host $searchQuery -foregroundcolor Red }
            return $null
		}
    }
    catch { 
        Write-Error "An error occurred: $_"
        return $null
    }
}

$ss = Get-TunebatData "Bad Omens - Just Pretend" -Verbose -extDetails
$t = "https://api.tunebat.com/api/tracks?trackid=$($ss.TunebatID)"
$t