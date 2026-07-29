# ---------------------------------------------------------------------------
# FLOW Lab site - asset localization for Windows (PowerShell version).
#
# Does exactly what scripts/fetch_assets.sh does, with no bash/curl/perl needed.
# Downloads each asset from the live site into the assets\ subfolders and
# rewrites the HTML + publications.bib to use the local copy.
#
# You do NOT need this to TEST the site - it is the final step before the old
# WordPress server is retired. Run it once, when you are ready to make the
# site fully self-contained.
#
#   Right-click this file -> "Run with PowerShell"
#   or:  powershell -ExecutionPolicy Bypass -File scripts\fetch_assets.ps1
#
# Safe to re-run: existing files are kept, already-rewritten links are left
# alone, and anything that fails to download stays pointing at the live site
# and is reported at the end.
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Stop"

# Always operate from the site root (the folder containing index.html),
# regardless of where the script is launched from.
Set-Location (Split-Path $PSScriptRoot -Parent)

# local path  =  remote URL
$assets = @(
  @("assets/people/makiharju-simo.jpg", "https://flow.berkeley.edu/wp-content/uploads/2015/05/134cropped.jpg"),
  @("assets/people/thacher-eric.jpg", "https://flow.berkeley.edu/wp-content/uploads/2015/05/Thacher-Eric.jpg"),
  @("assets/people/kokubun-andrew.png", "https://flow.berkeley.edu/wp-content/uploads/2022/02/kokubun-andrew-1.png"),
  @("assets/people/ali-alaa.png", "https://flow.berkeley.edu/wp-content/uploads/2022/07/AlaaAli.png"),
  @("assets/people/orun-ozgur.png", "https://flow.berkeley.edu/wp-content/uploads/2022/07/OzgurOrun.png"),
  @("assets/people/sweet-lilly.jpg", "https://flow.berkeley.edu/wp-content/uploads/2025/08/LillySweet.jpg"),
  @("assets/people/belin-tim.jpg", "https://flow.berkeley.edu/wp-content/uploads/2026/04/Tim-Belin-893x1024.jpg"),
  @("assets/people/group-fall-2024.jpg", "https://flow.berkeley.edu/wp-content/uploads/2024/10/FallLunch2024_cropped-1024x530.jpg"),
  @("assets/research/air-layer-drag-reduction.png", "https://flow.berkeley.edu/wp-content/uploads/2015/05/FDR_fig13.png"),
  @("assets/research/xray-void-fraction.png", "https://flow.berkeley.edu/wp-content/uploads/2015/05/xray_example.png"),
  @("assets/research/shs-drag-reduction.png", "https://flow.berkeley.edu/wp-content/uploads/2018/05/SHS_DR_EXAMPLE.png"),
  @("assets/research/gap-cavitation.mp4", "https://flow.berkeley.edu/wp-content/uploads/2018/05/GapCavitation.mp4"),
  @("assets/towing-tank/tank-01.jpg", "https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_121515.jpg"),
  @("assets/towing-tank/tank-02.jpg", "https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_121540.jpg"),
  @("assets/towing-tank/tank-03.jpg", "https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_141024.jpg"),
  @("assets/towing-tank/tank-04.jpg", "https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_141101.jpg"),
  @("assets/outreach/classroom-demo.jpg", "https://flow.berkeley.edu/wp-content/uploads/2020/03/20200219_105325-1024x768.jpg"),
  @("assets/img/sponsors/neup.png", "https://neup.inl.gov/SiteAssets/NEUP%20Logo-Gold.png"),
  @("assets/img/sponsors/psc.png", "https://flow.berkeley.edu/wp-content/uploads/2019/12/PSC.png"),
  @("assets/img/sponsors/citris.png", "https://flow.berkeley.edu/wp-content/uploads/2020/05/Citris-1024x385.png"),
  @("assets/img/sponsors/aifs.png", "https://flow.berkeley.edu/wp-content/uploads/2022/08/AIFS_logo.png"),
  @("assets/img/sponsors/gryphon.png", "https://flow.berkeley.edu/wp-content/uploads/2022/08/Gryphon_logo.png"),
  @("assets/img/sponsors/hellman.png", "https://flow.berkeley.edu/wp-content/uploads/2022/08/Hellman_logo.png"),
  @("assets/papers/pdf/C13_MakiharjuCeccio2016Experimental.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C13_MakiharjuCeccio2016Experimental.pdf"),
  @("assets/papers/pdf/C14_Gose2017Experimental.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C14_Gose2017Experimental.pdf"),
  @("assets/papers/pdf/C15_Li2018Cavitation.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C15_Li2018Cavitation.pdf"),
  @("assets/papers/pdf/C16_Peifer2018AirLayer.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C16_Peifer2018AirLayer.pdf"),
  @("assets/papers/pdf/C19_Zha2019Breaching.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C19_Zha2019Breaching.pdf"),
  @("assets/papers/pdf/C20_Jain2019Modeling.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C20_Jain2019Modeling.pdf"),
  @("assets/papers/pdf/C21_CallahanDudley2020Superhydrophobic.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C21_CallahanDudley2020Superhydrophobic.pdf"),
  @("assets/papers/pdf/C22_CallahanDudleyMakiharju2021Cavitating.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C22_CallahanDudleyMakiharju2021Cavitating.pdf"),
  @("assets/papers/pdf/C24_PelzerMakiharju2022Considering.pdf", "https://flow.berkeley.edu/wp-content/uploads/2023/08/C24_PelzerMakiharju2022Considering.pdf")
)

# UTF-8 without BOM, so diacritics in publications.bib stay intact.
$utf8 = New-Object System.Text.UTF8Encoding($false)
$targets = (Get-ChildItem -Filter *.html).FullName + (Resolve-Path publications.bib).Path

$ok = 0; $fail = 0
foreach ($pair in $assets) {
  $local = $pair[0]; $remote = $pair[1]
  $got = $true
  if (-not (Test-Path $local)) {
    $dir = Split-Path $local -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try {
      Invoke-WebRequest -Uri $remote -OutFile $local -UseBasicParsing
    } catch {
      Write-Host "WARN: could not fetch $remote - left pointing at the live site"
      $got = $false; $fail++
    }
  }
  if ($got) {
    # Rewrite this asset's references everywhere (no-op if already local).
    foreach ($f in $targets) {
      $text = [System.IO.File]::ReadAllText($f)
      if ($text.Contains($remote)) {
        [System.IO.File]::WriteAllText($f, $text.Replace($remote, $local), $utf8)
      }
    }
    $ok++
  }
}

Write-Host "----------------------------------------------------------------------"
Write-Host "$ok assets localized, $fail left remote."
if ($fail -eq 0) { Write-Host "The site is now fully self-contained." }
