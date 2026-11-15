$ErrorActionPreference = "Stop"
try {
    [xml]$doc = Get-Content -Raw "D:\Roblox\StealAnEgg\StealAnEgg.rbxlx"
    $workspace = $doc.roblox.ChildNodes | Where-Object { $_.LocalName -eq "Item" -and $_.GetAttribute("class") -eq "Workspace" }
    $pack = $workspace.ChildNodes | Where-Object { $_.LocalName -eq "Item" } | Where-Object {
        ($_.Properties.ChildNodes | Where-Object { $_.LocalName -eq "string" -and $_.name -eq "Name" }).InnerText -eq "UIMegaPack"
    }
    $count = 0
    function Count-Items($node) {
        foreach ($child in $node.ChildNodes) {
            if ($child.LocalName -eq "Item") {
                $script:count++
                Count-Items $child
            }
        }
    }
    if ($pack) { Count-Items $pack }
    Write-Output ("XML_OK pack_found=" + [bool]$pack + " pack_items=" + $count)
} catch {
    Write-Output ("XML_FAIL: " + $_.Exception.Message)
}
