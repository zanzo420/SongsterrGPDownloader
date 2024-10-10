#region Search Functions
function Get-UGSearchData([string]$queryString)
{
    try {
        # Validate the input queryString
        if ([string]::IsNullOrWhiteSpace($queryString)) {
            throw [System.ArgumentException]::new("Query string cannot be null or empty.")
        }
        # Escape the input queryString
        $cleanQuery = [URI]::EscapeUriString($queryString)
        # Form the search url
        $url = "https://www.ultimate-guitar.com/search.php?title=$($cleanQuery)&page=1&type=500"
        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Extract the HTML content
        $htmlContent = $response.Content
        # Define the regex pattern to match the data-content attribute of the js-store div class
        $regex_pattern = '<div class="js-store" data-content="([^"]*)">'
        # Use the regex_pattern to find the JSON search data
        $matches = [regex]::Matches($htmlContent, $regex_pattern)

        if ($matches.Count -eq 0) {
            throw [System.Exception]::new("No JSON data found in the HTML content.")
        }

        # Extract the JSON data from the contents of the 'data-content' attribute
        foreach ($match in $matches) {
            $dataContent = $match.Groups[1].Value
            $results = $dataContent.Replace("&quot;", '"')
        }
        # Create an object from the extracted JSON data
        $obj = $results | ConvertFrom-Json
        # Return just the search results data from the JSON object
        return $obj.store.page.data
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

function Get-UGSearchJSON([string]$searchQuery)
{
    # Validate the input url
    if ([string]::IsNullOrWhiteSpace($searchQuery)) {
        throw [System.ArgumentException]::new("SearchQuery cannot be null or empty.")
    }
    # Encode the search query for the URL
    $encodedQuery = [URI]::EscapeUriString($searchQuery)
    # Define the API endpoint url
    $apiUrl = "https://api.ultimate-guitar.com/search.php?search_type=title&value=$($encodedQuery)&type=500"
    # Perform the web request
    $response = Invoke-WebRequest -UseBasicParsing -Uri $apiUrl -Headers @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    }
    # Match and return the JSON data
    if($response.content -match '\<div class\=\"js-store\" data-content\=\"(.*)\"\>\<\/div\>'){
        $data = "$($Matches[0].Replace("&quot;", '"').Replace("&amp;", '&').Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('\\"', '"').Replace("`n", ''))"
        return $data
    }else{
        write-host "ERROR: No 'js-store' data found!" -ForegroundColor Red
        return $null
    }
}

function Check-UGHasProTab([string]$query, [switch]$Verbose)
{
    $ResObj = Get-UGSearchData "$($query)"

    if ($ResObj) {
        if ($Verbose) {
            Write-Host 'Guitar Pro tab for "' -NoNewline
            Write-Host "$($query)" -NoNewline -ForegroundColor Green
            Write-Host '" found on Ultimate-Guitar'
            Write-Host "Results Count: " -NoNewline
            Write-Host "$($ResObj.results_count)" -ForegroundColor Green
            $i = 0
            foreach ($res in $ResObj.results) {
                if ($res.type -eq "Pro") {
                    Write-Host "[$($i)] Tab URL: " -NoNewline
                    Write-Host "$($ResObj.results[$i].tab_url)" -ForegroundColor Green
                }
                $i++
            }
        }
        return $true
    } else {
        if ($Verbose) { Write-Host "No results found." -ForegroundColor Red }
        return $false
    }
}
#endregion

#region MetaData Functions
##
# Get the metadata of a pro tab on Ultimate-Guitar by SongID
function Get-UGProMetaData([int]$SongID)
{
    try {
        # Validate the input SongID
        if (!$SongID) {
            throw [System.ArgumentException]::new("SongID cannot be null or empty.")
        }
        # Form the UG MetaData API url
        $url = "https://api-web.ultimate-guitar.com/v1/tab/pro/meta?id=$($SongID)"
        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Create an object from the JSON meta data and return it
        return $response.content | ConvertFrom-Json
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

function Get-UGMetaData([string]$url)
{
    $res = Invoke-WebRequest -Uri $url -UseBasicParsing
    if($res.content -match '\<div class\=\"js-store\" data-content\=\"(.*)\"\>\<\/div\>'){
        $data = "$($Matches[0].Replace("&quot;", '"').Replace("&amp;", '&').Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('\\"', '"').Replace("`n", ''))"
        return ($data | ConvertFrom-Json).store.page.data
    }else{
        write-host "ERROR: No 'js-store' data found!" -ForegroundColor Red
        return $null
    }
}
function Get-UGPageData([string]$url)
{
    $res = Invoke-WebRequest -UseBasicParsing -Uri [URI]::EscapeUriString($url) #"https://www.ultimate-guitar.com/explore?order=date_desc&type[]=Official"
    if($res.content -match '\<div class\=\"js-store\" data-content\=\"(.*)\"\>\<\/div\>'){
        $data = "$($Matches[0].Replace("&quot;", '"').Replace("&amp;", '&').Replace('<div class="js-store" data-content="', '').Replace('"></div>', '').Replace('\\"', '"').Replace("`n", ''))"
        return ConvertFrom-Json($data)
    }else{
        return write-host "Json data not found!"
    }
}

function Get-UGPageJSON([string]$url)
{
    try {
        # Validate the input url
        if ([string]::IsNullOrWhiteSpace($url)) {
            throw [System.ArgumentException]::new("URL cannot be null or empty.")
        }

        # Send the web request and get the response
        $response = Invoke-WebRequest -Uri $url
        # Extract the HTML content
        $htmlContent = $response.Content
        # Define the regex pattern to match the data-content attribute of the js-store div class
        $regex_pattern = '<div class="js-store" data-content="([^"]*)">'
        # Use the regex_pattern to find the JSON data
        $matches = [regex]::Matches($htmlContent, $regex_pattern)

        if ($matches.Count -eq 0) {
            throw [System.Exception]::new("No JSON data found in the HTML content.")
        }

        # Extract the JSON data from the contents of the 'data-content' attribute
        foreach ($match in $matches) {
            $dataContent = $match.Groups[1].Value
            $results = $dataContent.Replace("&quot;", '"')
        }
        # Return the JSON data from the page
        return $results | ConvertFrom-Json
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
#endregion


#region Execute On Script Load
Check-UGHasProTab "Falling In Reverse - I am not a vampire" #-Verbose
#endregion