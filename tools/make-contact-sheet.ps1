$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$items = @(
    @{ id = 75730579249181; label = "Robux-2" },
    @{ id = 101558165672828; label = "Money-2" },
    @{ id = 122271314890881; label = "Rebirth-2" },
    @{ id = 95705000553415; label = "Shop-2" },
    @{ id = 111647672177103; label = "Pets-2" },
    @{ id = 89960202252554; label = "Settings-2" },
    @{ id = 108468478600761; label = "Codes-2" },
    @{ id = 133321613198850; label = "Back-2" },
    @{ id = 126199909421060; label = "Delete-2" },
    @{ id = 137652172839461; label = "Correct-2" },
    @{ id = 73460904721476; label = "Forward-2" },
    @{ id = 126091452202940; label = "WheelSpin-2" },
    @{ id = 91995081088792; label = "Gift-2" },
    @{ id = 86221260122283; label = "Trade-2" },
    @{ id = 71185215827539; label = "Luck-2" },
    @{ id = 129479735876075; label = "Gems-2" },
    @{ id = 108708296046837; label = "SuperGems-2" },
    @{ id = 131198923284739; label = "Robux-1" },
    @{ id = 134033317054407; label = "Money-1" },
    @{ id = 115325120904186; label = "Rebirth-1" },
    @{ id = 79189567200992; label = "Shop-1" },
    @{ id = 110467625627559; label = "Pets-1" },
    @{ id = 79312800758069; label = "Settings-1" },
    @{ id = 74993576301387; label = "Codes-1" }
)

$ids = ($items | ForEach-Object { $_.id }) -join ","
$thumbPath = "D:\Roblox\StealAnEgg\ui-pack-preview\sheet-thumbs.json"
Invoke-WebRequest -UseBasicParsing -Uri "https://thumbnails.roblox.com/v1/assets?assetIds=$ids&size=150x150&format=Png" -OutFile $thumbPath
$thumbData = Get-Content -Raw $thumbPath | ConvertFrom-Json

$map = @{}
foreach ($entry in $thumbData.data) { $map[[string]$entry.targetId] = $entry.imageUrl }

$cell = 160
$labelH = 20
$cols = 5
$rows = [math]::Ceiling($items.Count / $cols)
$bmp = New-Object System.Drawing.Bitmap ($cols * $cell), ($rows * ($cell + $labelH))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(28, 26, 36))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

for ($i = 0; $i -lt $items.Count; $i++) {
    $item = $items[$i]
    $url = $map[[string]$item.id]
    if (-not $url) { continue }
    $file = "D:\Roblox\StealAnEgg\ui-pack-preview\sheet_$($item.id).png"
    if (-not (Test-Path $file)) { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $file }
    $img = [System.Drawing.Image]::FromFile($file)
    $x = [int](($i % $cols) * $cell)
    $y = [int]([math]::Floor($i / $cols) * ($cell + $labelH))
    $rect = [System.Drawing.Rectangle]::new([int]($x + 5), [int]($y + 5), [int]($cell - 10), [int]($cell - 10))
    $g.DrawImage($img, $rect)
    $img.Dispose()
    $g.DrawString($item.label, $font, $brush, $x + 5, $y + $cell + 2)
}

$out = "D:\Roblox\StealAnEgg\ui-pack-preview\contact-sheet-2.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Output "Wrote $out"
