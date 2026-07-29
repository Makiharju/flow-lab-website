#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# FLOW Lab site — asset localization (download + relink).
#
# Out of the box the site loads photos, videos, sponsor logos and paper PDFs
# from the current WordPress server, so it works immediately. Run this script
# ONCE (while flow.berkeley.edu is still up) to make the site fully
# self-contained: it downloads each file into the right assets/ subfolder and
# rewrites the HTML + publications.bib to use the local copy.
#
#   usage:  bash scripts/fetch_assets.sh     (from anywhere; it cd's itself)
#
# Safe to re-run: existing files are kept, already-rewritten references are
# untouched, and any file that fails to download is simply left pointing at
# the live site (and reported at the end).
# ---------------------------------------------------------------------------
cd "$(dirname "$0")/.."           # always operate from the site root
ok=0; fail=0

while read -r local remote; do
  [ -z "$local" ] && continue
  if [ -f "$local" ] || curl -fSL --create-dirs -o "$local" "$remote"; then
    # relink this asset everywhere (no-op if already local)
    perl -pi -e "s{\Q$remote\E}{$local}g" ./*.html publications.bib
    ok=$((ok+1))
  else
    echo "WARN: could not fetch $remote — reference left pointing at the live site"
    rm -f "$local"
    fail=$((fail+1))
  fi
done <<'MANIFEST'
assets/people/makiharju-simo.jpg https://flow.berkeley.edu/wp-content/uploads/2015/05/134cropped.jpg
assets/people/thacher-eric.jpg https://flow.berkeley.edu/wp-content/uploads/2015/05/Thacher-Eric.jpg
assets/people/kokubun-andrew.png https://flow.berkeley.edu/wp-content/uploads/2022/02/kokubun-andrew-1.png
assets/people/ali-alaa.png https://flow.berkeley.edu/wp-content/uploads/2022/07/AlaaAli.png
assets/people/orun-ozgur.png https://flow.berkeley.edu/wp-content/uploads/2022/07/OzgurOrun.png
assets/people/sweet-lilly.jpg https://flow.berkeley.edu/wp-content/uploads/2025/08/LillySweet.jpg
assets/people/belin-tim.jpg https://flow.berkeley.edu/wp-content/uploads/2026/04/Tim-Belin-893x1024.jpg
assets/people/group-fall-2024.jpg https://flow.berkeley.edu/wp-content/uploads/2024/10/FallLunch2024_cropped-1024x530.jpg
assets/research/air-layer-drag-reduction.png https://flow.berkeley.edu/wp-content/uploads/2015/05/FDR_fig13.png
assets/research/xray-void-fraction.png https://flow.berkeley.edu/wp-content/uploads/2015/05/xray_example.png
assets/research/shs-drag-reduction.png https://flow.berkeley.edu/wp-content/uploads/2018/05/SHS_DR_EXAMPLE.png
assets/research/gap-cavitation.mp4 https://flow.berkeley.edu/wp-content/uploads/2018/05/GapCavitation.mp4
assets/towing-tank/tank-01.jpg https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_121515.jpg
assets/towing-tank/tank-02.jpg https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_121540.jpg
assets/towing-tank/tank-03.jpg https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_141024.jpg
assets/towing-tank/tank-04.jpg https://flow.berkeley.edu/wp-content/uploads/2018/06/20180612_141101.jpg
assets/outreach/classroom-demo.jpg https://flow.berkeley.edu/wp-content/uploads/2020/03/20200219_105325-1024x768.jpg
assets/img/sponsors/neup.png https://neup.inl.gov/SiteAssets/NEUP%20Logo-Gold.png
assets/img/sponsors/psc.png https://flow.berkeley.edu/wp-content/uploads/2019/12/PSC.png
assets/img/sponsors/citris.png https://flow.berkeley.edu/wp-content/uploads/2020/05/Citris-1024x385.png
assets/img/sponsors/aifs.png https://flow.berkeley.edu/wp-content/uploads/2022/08/AIFS_logo.png
assets/img/sponsors/gryphon.png https://flow.berkeley.edu/wp-content/uploads/2022/08/Gryphon_logo.png
assets/img/sponsors/hellman.png https://flow.berkeley.edu/wp-content/uploads/2022/08/Hellman_logo.png
assets/papers/pdf/C13_MakiharjuCeccio2016Experimental.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C13_MakiharjuCeccio2016Experimental.pdf
assets/papers/pdf/C14_Gose2017Experimental.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C14_Gose2017Experimental.pdf
assets/papers/pdf/C15_Li2018Cavitation.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C15_Li2018Cavitation.pdf
assets/papers/pdf/C16_Peifer2018AirLayer.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C16_Peifer2018AirLayer.pdf
assets/papers/pdf/C19_Zha2019Breaching.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C19_Zha2019Breaching.pdf
assets/papers/pdf/C20_Jain2019Modeling.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C20_Jain2019Modeling.pdf
assets/papers/pdf/C21_CallahanDudley2020Superhydrophobic.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C21_CallahanDudley2020Superhydrophobic.pdf
assets/papers/pdf/C22_CallahanDudleyMakiharju2021Cavitating.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C22_CallahanDudleyMakiharju2021Cavitating.pdf
assets/papers/pdf/C24_PelzerMakiharju2022Considering.pdf https://flow.berkeley.edu/wp-content/uploads/2023/08/C24_PelzerMakiharju2022Considering.pdf
MANIFEST

echo "----------------------------------------------------------------------"
echo "$ok assets localized, $fail left remote."
[ "$fail" -eq 0 ] && echo "The site is now fully self-contained."
