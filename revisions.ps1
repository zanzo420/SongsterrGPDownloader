function Get-RevisionsData($SongID)
{
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0"
    $response = Invoke-RestMethod -Uri "https://www.songsterr.com/api/meta/$($SongID)/revisions" `
    -WebSession $session `
    -Headers @{
    "sec-ch-ua-platform"="`"Windows`""
    "Referer"="https://www.songsterr.com"
    "sec-ch-ua"="`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
    "DNT"="1"
    "sec-ch-ua-mobile"="?0"
    }

    return $response
}

function Get-SongIdFromUrl($url)
{
    $result = $url -match '(?>.*\-tab\-s)(?<songid>[0-9]*)'
    return $matches['songid']
}

$sID = Get-SongIdFromUrl("https://www.songsterr.com/a/wsa/metallica-nothing-else-matters-drum-tab-s439171")
$revisions = Get-RevisionsData($sID)

write-host "`nTotal Revisions: " -nonewline; write-host ($revisions.count - 1) -ForegroundColor Cyan
write-host "-------------------" -ForegroundColor Gray
$indx = 0
foreach($rev in $revisions){
    write-host "[" -nonewline; write-host $($indx) -nonewline -ForegroundColor Green; write-host "] $($rev.revisionId)"
    $indx++    
}
$revisions[0]