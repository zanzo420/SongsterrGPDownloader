<#
.SYNOPSIS
Open a Tunebat search for a given query.

.DESCRIPTION
This function opens a web browser to the Tunebat search page with the specified search query. The search query is URL-encoded before being appended to the Tunebat search URL.

.PARAMETER SearchQuery
The search query to be used in the Tunebat search.

.EXAMPLE
Open-Tunebat "Bad Omens - Just Pretend"

.NOTES
Author: Zanzo
#>
function Open-Tunebat([string]$SearchQuery)
{
    write-host "Opening Tunebat search for: " -nonewline; write-host $SearchQuery -foregroundcolor Green
    $url = "https://www.tunebat.com/Search?q=$([URI]::EscapeUriString($SearchQuery))"
    Start-Process $url
}

function Open-TunebatSearch([string]$Artist, [string]$Title)
{
    [string]$SearchQuery = "$($Artist) - $($Title)"
    $escQuery = [URI]::EscapeUriString($SearchQuery)
    write-host "Opening Tunebat search for: " -nonewline; write-host $SearchQuery -foregroundcolor Green
    $url = "https://www.tunebat.com/Search?q=$($escQuery)"
    Start-Process msedge $url
}

Open-TunebatSearch -Artist "Bad Omens" -Title "Just Pretend"

<#
.SYNOPSIS
Get Tunebat data for a given search query.

.DESCRIPTION
This function retrieves Tunebat data for a given search query. It sends an HTTP GET request to the Tunebat API with the search query and retrieves the top search result. The function then extracts relevant data from the search result and returns it as a custom object.

.PARAMETER SearchQuery
The search query to be sent to the Tunebat API.

.PARAMETER extDetails
Switch to include extended details in the output.

.PARAMETER Verbose
Switch to enable verbose output.

.EXAMPLE
Get-TunebatData -SearchQuery "Bad Omens - Just Pretend" -Verbose -extDetails

.NOTES
Author: Zanzo
Date: 2022-03-01
#>
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
            $TunebatData = [PSCustomObject]@{
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

            if($Verbose){   # Display the song details
                Write-Host "`n---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Tunebat Search Result for " -nonewline -BackgroundColor Black; Write-Host $SearchQuery -ForegroundColor Green -BackgroundColor Black
                write-host "---------------------------------------------------" -ForegroundColor Gray
                Write-Host "Title:`t" -nonewline; Write-Host "$($TunebatData.SongName)" -foregroundcolor Green
                Write-Host "Artist:`t" -nonewline; Write-Host "$($TunebatData.artistName)" -foregroundcolor Green
                if($extDetails){ Write-Host "Album:`t" -nonewline; Write-Host "$($TunebatData.album)" -foregroundcolor Green -NoNewline; Write-Host " (" -nonewline; Write-Host "$($TunebatData.releaseDate)" -foregroundcolor DarkGreen -NoNewline; Write-Host ")" }
                Write-Host "Key:`t" -nonewline; Write-Host "$($TunebatData.key)" -foregroundcolor Green -NoNewline; write-host " (" -nonewline; write-host "$($TunebatData.key.Replace(' Minor','m').Replace(' Major',''))" -ForegroundColor Green -NoNewline; write-host ") $($TunebatData.keyValue)"
                Write-Host "Tempo:`t" -nonewline; Write-Host "$($TunebatData.tempo)" -foregroundcolor Green 
                if($extDetails){ Write-Host "Popularity:`t" -nonewline; Write-Host "$($TunebatData.popularity)" -foregroundcolor Green; Write-Host "Album Art:`t" -nonewline; Write-Host "$($TunebatData.coverImage)" -foregroundcolor Green }
            }
            return $TunebatData
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