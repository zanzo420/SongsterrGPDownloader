

#region Ultimate-Guitar Search Functions
function Get-UGSearchJSON([string]$searchQuery)
{
    # Encode the search Query for URL
    $encodedSearchQuery = [URI]EscapeUriString($searchQuery)

    # Define the API endpoint
    $apiUrl = httpsapi.ultimate-guitar.comsearch.phpsearch_type=title&value=$($encodedSearchQuery)&type=300

    # Perform the web request
    $response = Invoke-WebRequest -UseBasicParsing -Uri $apiUrl -Headers @{
        User-Agent = Mozilla5.0 (Windows NT 10.0; Win64; x64) AppleWebKit537.36 (KHTML, like Gecko) Chrome58.0.3029.110 Safari537.3
    }
    if($response.content -match 'div class=js-store data-content=(.)div'){
        $data = $($Matches[0].Replace(&quot;, '').Replace(&amp;, '&').Replace('div class=js-store data-content=', '').Replace('div', '').Replace('', '').Replace(`n, ''))
        return $data
    }else{
        write-host ERROR No 'js-store' data found for $($searchQuery)! -ForegroundColor Red
        return $null
    }

    # Parse the JSON content
    $jsonContent = $data  ConvertFrom-Json

    # Display the results
    if ($jsonContent.results.Count -gt 0) {
        Write-Output Found the following Guitar Pro tabs
        foreach ($result in $jsonContent.results) {
            Write-Output $result.tab_url
        }
    } else {
        Write-Output No Guitar Pro tabs found for '$($searchQuery)'.
    }
}
#endregion


#region Ultimate-Guitar MetaData Functions
function Get-UGMetaData([string]$url){
    $res = Invoke-WebRequest -Uri $url -UseBasicParsing
    if($res.content -match 'div class=js-store data-content=(.)div'){
        $data = $($Matches[0].Replace(&quot;, '').Replace(&amp;, '&').Replace('div class=js-store data-content=', '').Replace('div', '').Replace('', '').Replace(`n, ''))
        return $data  ConvertFrom-Json
    }else{
        write-host ERROR No 'js-store' data found! -ForegroundColor Red
        return $null
    }
}
function Get-UGPageData([string]$url){
    $res = Invoke-WebRequest -UseBasicParsing -Uri [URI]EscapeUriString($url) #httpswww.ultimate-guitar.comexploreorder=date_desc&type[]=Official
    if($res.content -match 'div class=js-store data-content=(.)div'){
        $data = $($Matches[0].Replace(&quot;, '').Replace(&amp;, '&').Replace('div class=js-store data-content=', '').Replace('div', '').Replace('', '').Replace(`n, ''))
        return ConvertFrom-Json($data)
    }else{
        return write-host Json data not found!
    }
}
#endregion