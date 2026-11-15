$ErrorActionPreference = "Stop"
[xml]$x = Get-Content -Raw "D:\Roblox\StealAnEgg\StealAnEgg.rbxlx"

function Get-Name($item) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq "string" -and $_.name -eq "Name" }
    if ($node) { return [string]$node.InnerText }
    return ""
}

function Get-Simple($item, [string]$type, [string]$name) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq $type -and $_.name -eq $name }
    if ($node) { return [string]$node.InnerText }
    return ""
}

function Get-ContentId($item, [string]$name) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq "Content" -and $_.name -eq $name }
    if (-not $node) { return "" }
    $uri = $node.ChildNodes | Where-Object { $_.LocalName -eq "uri" }
    if ($uri) { return [string]$uri.InnerText }
    return ""
}

function Child($node, [string]$name) {
    return ($node.ChildNodes | Where-Object { $_.LocalName -eq $name } | Select-Object -First 1)
}

function Get-Udim2($item, [string]$name) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq "UDim2" -and $_.name -eq $name }
    if (-not $node) { return "" }
    return ((Child $node "XS").InnerText + "/" + (Child $node "XO").InnerText + " x " + (Child $node "YS").InnerText + "/" + (Child $node "YO").InnerText)
}

function Get-Vector2($item, [string]$name) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq "Vector2" -and $_.name -eq $name }
    if (-not $node) { return "" }
    return ((Child $node "X").InnerText + "," + (Child $node "Y").InnerText)
}

function Get-Slice($item) {
    $node = $item.Properties.ChildNodes | Where-Object { $_.LocalName -eq "Rect2D" -and $_.name -eq "SliceCenter" }
    if (-not $node) { return "" }
    $min = Child $node "min"; $max = Child $node "max"
    return ((Child $min "X").InnerText + "-" + (Child $min "Y").InnerText + "|" + (Child $max "X").InnerText + "-" + (Child $max "Y").InnerText)
}

$rows = New-Object System.Collections.Generic.List[object]
$script:index = 0

function Walk($item, [string]$path) {
    $name = Get-Name $item
    $newPath = if ($path) { "$path > $name" } else { $name }
    $script:index++
    $rows.Add([pscustomobject]@{
        Id = $script:index
        Path = $newPath
        Class = [string]$item.GetAttribute("class")
        Image = Get-ContentId $item "ImageContent"
        Texture = Get-ContentId $item "TextureContent"
        Size = Get-Udim2 $item "Size"
        Position = Get-Udim2 $item "Position"
        Anchor = Get-Vector2 $item "AnchorPoint"
        RectOffset = Get-Vector2 $item "ImageRectOffset"
        RectSize = Get-Vector2 $item "ImageRectSize"
        Slice = Get-Slice $item
        ScaleType = Get-Simple $item "token" "ScaleType"
        Text = Get-Simple $item "string" "Text"
        Visible = Get-Simple $item "bool" "Visible"
    })
    foreach ($child in $item.ChildNodes) {
        if ($child.LocalName -eq "Item") { Walk $child $newPath }
    }
}

$workspace = $x.roblox.ChildNodes | Where-Object { $_.LocalName -eq "Item" -and (Get-Name $_) -eq "Workspace" }
$pack = $workspace.ChildNodes | Where-Object { $_.LocalName -eq "Item" -and (Get-Name $_) -eq "UIMegaPack" }
if (-not $pack) { throw "UIMegaPack not found" }
Walk $pack ""

$rows | Export-Csv -Path "D:\Roblox\StealAnEgg\ui-pack-inventory.csv" -NoTypeInformation -Encoding UTF8
Write-Output ("items=" + $rows.Count)
