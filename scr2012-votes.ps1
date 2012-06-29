$baseUri = "http://sanriocharacterranking.com/"
$lowerUri = $baseUri + "rankingall.php"

$date = (Get-Date).Date

function wget([String]$uri) {
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.DownloadString($uri)
}
function new-resultline([int]$rank, [int]$id, [string]$name, [int]$votes) {
    New-Object PSObject -Property @{
        Date = $date;
        Rank = $rank;
        CID = $id;
        Name = $name;
        Votes = $votes;
    }
}
function get-top10() {
    $body = wget($baseUri)
    $body -split "<li " |
        % {
            if ($_ -match "rank(\d+)") {
                $rank = [int]$Matches[1]
            } else { return }
            if ($_ -match " chr(\d+)") {
                $id = [int]$Matches[1]
            } else { return }
            if ($_ -match "<strong><span>(.+)</span></strong>") {
                $name = $Matches[1]
            } else { return }
            if ($_ -match "得票数&nbsp;([\d,]+)票") {
                $votes = [int]$Matches[1]
            } else { return }
            new-resultline $rank $id $name $votes
        }
}
function get-lower() {
    $body = wget($lowerUri)
    $body -split "<li " |
        % {
            if ($_ -match "(\d+)位") {
                $rank = [int]$Matches[1]
            } else { return }
            if ($_ -match "chr(\d+)") {
                $id = [int]$Matches[1]
            } else { return }
            if ($_ -match "<strong>(.+)</strong>") {
                $name = $Matches[1]
            } else { return }
            if ($_ -match "([\d,]+)&nbsp;票") {
                $votes = [int]$Matches[1]
            } else { return }
            new-resultline $rank $id $name $votes
        }
}

$votes = @(get-top10) + @(get-lower)

if($votes.Count -ne 100) {
    Write-Error ("Number of characters is {0}. Expecting 100." -f $votes.Count)
}
if(($votes | group CID | measure -Maximum Count).Maximum -ne 1) {
    Write-Error "CID Duplicated"
}
$votes | group Rank |? {$_.Count -ge 2} |% {Write-Warning ("{0} duplicates in rank {1}" -f $_.Count,$_.Name)}

