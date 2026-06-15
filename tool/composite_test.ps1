# Offline anchor-tuning harness for the avatar layer composite.
# Usage: powershell -File tool/composite_test.ps1 -EyesTop 41 -HairTop -2 -TopTop 130 -BottomTop 188
param(
  [int]$EyesTop = 58,
  [double]$EyesScale = 0.62,
  [int]$HairTop = -2,
  [double]$HairScale = 1.0,
  [int]$TopTop = 130,
  [double]$TopScale = 1.0,
  [int]$BottomTop = 188,
  [double]$BottomScale = 1.0,
  [string]$Hair = "sprites\hair\hair_001.png",
  [string]$Top = "sprites\clothes\rpg_neutral\tops\common\tops_common_001.png",
  [string]$Bottom = "sprites\clothes\modern_masculine\bottoms\common\bottoms_common_001.png",
  [string]$Out = "$env:TEMP\avatar_composite.png"
)
Add-Type -AssemblyName System.Drawing

$canvasW = 141; $canvasH = 284
$bmp = New-Object System.Drawing.Bitmap($canvasW, $canvasH)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'NearestNeighbor'

function Draw-Layer($path, $top, $scale = 1.0) {
  $img = [System.Drawing.Bitmap]::FromFile("$pwd\$path")
  $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
  $left = [int](($canvasW - $w) / 2)
  $script:g.DrawImage($img, $left, $top, $w, $h)
  $img.Dispose()
}

Draw-Layer "sprites\avatars\skin_tones\light.png" 0
Draw-Layer "sprites\eyes\blue.png" $EyesTop $EyesScale
Draw-Layer $Bottom $BottomTop $BottomScale
Draw-Layer $Top $TopTop $TopScale
Draw-Layer $Hair $HairTop $HairScale
$g.Dispose()

# Save at 2x for easier inspection.
$big = New-Object System.Drawing.Bitmap(($canvasW*2), ($canvasH*2))
$g2 = [System.Drawing.Graphics]::FromImage($big)
$g2.InterpolationMode = 'NearestNeighbor'
$g2.PixelOffsetMode = 'Half'
$g2.DrawImage($bmp, 0, 0, ($canvasW*2), ($canvasH*2))
$g2.Dispose()
$big.Save($Out)
$big.Dispose(); $bmp.Dispose()
Write-Output "saved $Out"
