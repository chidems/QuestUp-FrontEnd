# Downscales an emulator screenshot (captured via adb in bash) to half size.
param(
  [string]$In = "$env:TEMP\shot_raw.png",
  [string]$Out = "$env:TEMP\shot_small.png"
)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile($In)
$small = New-Object System.Drawing.Bitmap([int]($src.Width/2), [int]($src.Height/2))
$g = [System.Drawing.Graphics]::FromImage($small)
$g.InterpolationMode = 'HighQualityBicubic'
$g.DrawImage($src, 0, 0, $small.Width, $small.Height)
$g.Dispose(); $src.Dispose()
if (Test-Path $Out) { Remove-Item $Out }
$small.Save($Out); $small.Dispose()
Write-Output "saved $Out"
