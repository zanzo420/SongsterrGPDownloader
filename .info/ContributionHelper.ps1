#region Imports
. .\UG.ps1
. .\SongsterrGPDownloader.ps1
. .\tunebat.ps1
. .\youtube.ps1
#endregion
#region Contribution Helper Functions
function ContributionHelper([string]$Artist, [string]$Title)
{
    $searchQuery = "$($Artist) - $($Title)"
    #search for song on Tunebat...
    $json = Get-TunebatData($searchQuery)

    $tunebatID = $json.items[0].id
    $name = $json.items[0].n
    $artist = $json.items[0].as[0]
    $cleaned = "$($name.Replace(' ', '-'))-$($artist.Replace(' ', '-'))"
    write-host $cleaned
    $tunebatUrl = "https://tunebat.com/$($cleaned)/$($tunebatID)"
    write-host $tunebatUrl
    start-process msedge $tunebatUrl
}
#endregion

ContributionHelper -Artist "Bad Omens" -Title "Just Pretend"