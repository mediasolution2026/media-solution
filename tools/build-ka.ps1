# Generates the Georgian site (/ka/...) from the English pages + tools/ka.txt,
# adds hreflang + language switcher to the English pages, and rewrites sitemap.xml.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less scripts as ANSI).
# Usage: powershell -File tools\build-ka.ps1   (re-run after editing any English page or ka.txt)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$enc = New-Object System.Text.UTF8Encoding($false)
$site = 'https://mediasolution.ge'
$em = [string][char]0x2014
$today = Get-Date -Format 'yyyy-MM-dd'

function ReadText($p) { return ([System.IO.File]::ReadAllText($p, $enc)) -replace "`r`n", "`n" }
function WriteText($p, $t) {
  $d = Split-Path -Parent $p
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
  [System.IO.File]::WriteAllText($p, ($t -replace "`r`n", "`n"), $enc)
}
function Esc($s) { return $s.Replace('&', '&amp;').Replace('"', '&quot;').Replace('<', '&lt;').Replace('>', '&gt;') }
function EscText($s) { return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }

# ---------- dictionary ----------
$dict = @{}
$lines = [System.IO.File]::ReadAllLines("$PSScriptRoot\ka.txt", $enc)
$i = 0
while ($i -lt $lines.Length) {
  if ($lines[$i].Trim() -eq '') { $i++; continue }
  $dict[$lines[$i].Trim()] = $lines[$i + 1].Trim()
  $i += 2
}
function T($k) { $k = $k.Replace('{S}', [string][char]0xA7); if (-not $dict.ContainsKey($k)) { throw "missing dictionary key: $k" }; return $dict[$k] }

$pages = @(
  @{ key = 'home'; path = '/'; file = 'index.html' },
  @{ key = 'about'; path = '/about/'; file = 'about\index.html' },
  @{ key = 'services'; path = '/services/'; file = 'services\index.html' },
  @{ key = 'careers'; path = '/careers/'; file = 'careers\index.html' },
  @{ key = 'contact'; path = '/contact/'; file = 'contact\index.html' },
  @{ key = 'privacy'; path = '/privacy/'; file = 'privacy\index.html' },
  @{ key = 'terms'; path = '/terms/'; file = 'terms\index.html' },
  @{ key = 'work'; path = '/work/'; file = 'work\index.html'; noindex = $true }
)
function KaPath($p) { if ($p -eq '/') { return '/ka/' } else { return '/ka' + $p } }

$svcDesc = @{
  'Strategy and Consulting' = 'Communication strategies that connect business objectives with audience needs, market realities and measurable outcomes.'
  'Media Planning and Distribution' = 'Campaigns designed to reach the right audiences in the right environments, with distribution treated as a strategic discipline.'
  'Content and Production' = 'Content created for the platforms, audiences and environments in which it will appear ' + $em + ' craft meets technology-enabled process.'
  'Influencer Marketing' = 'Collaborations that connect brands with audiences through credible voices and culturally relevant storytelling.'
  'Data Reporting and Measurement' = 'Campaign data transformed into clear insights that support better marketing decisions, before, during and after launch.'
  'Innovation and Client Enablement' = 'Helping clients understand, evaluate and implement emerging technologies and new approaches across the communications process.'
}
$orgDescKey = 'A technology-driven communications and media agency helping ambitious brands achieve measurable growth through strategy, content and intelligent distribution.'

function SetMeta($h, $attr, $name, $val) {
  $pat = '(<meta ' + $attr + '="' + [regex]::Escape($name) + '" content=")[^"]*(">)'
  $v = Esc $val
  return [regex]::Replace($h, $pat, { param($m) $m.Groups[1].Value + $v + $m.Groups[2].Value })
}

$missing = New-Object 'System.Collections.Generic.HashSet[string]'
function IsIgnorable($s) {
  return ($s -notmatch '[A-Za-z]') -or ($s -match '@') -or ($s -eq 'Media Solution') -or ($s -match '^\+?\d') -or ($s -eq 'cloudflare.com/privacypolicy')
}
function TranslateBody($body, $pageKey) {
  return [regex]::Replace($body, '>([^<>]+)<', {
    param($m)
    $raw = $m.Groups[1].Value
    $norm = [System.Net.WebUtility]::HtmlDecode(($raw -replace '\s+', ' ').Trim())
    if ($norm.Length -eq 0 -or (IsIgnorable $norm)) { return $m.Value }
    if ($dict.ContainsKey($norm)) {
      $lead = [regex]::Match($raw, '^\s*').Value
      $trail = [regex]::Match($raw, '\s*$').Value
      return '>' + $lead + (EscText $dict[$norm]) + $trail + '<'
    }
    [void]$missing.Add($pageKey + ' | ' + $norm)
    return $m.Value
  })
}

# ---------- 1. patch English pages (hreflang + language switcher), idempotent ----------
foreach ($p in $pages) {
  $f = Join-Path $root $p.file
  $h = ReadText $f
  $en = $site + $p.path
  $ka = $site + (KaPath $p.path)
  if ($h -notmatch 'hreflang="ka"') {
    $alt = '<link rel="alternate" hreflang="en" href="' + $en + '">' + "`n" + '<link rel="alternate" hreflang="ka" href="' + $ka + '">' + "`n" + '<link rel="alternate" hreflang="x-default" href="' + $en + '">'
    $h = $h.Replace('<link rel="canonical" href="' + $en + '">', '<link rel="canonical" href="' + $en + '">' + "`n" + $alt)
    $h = $h.Replace('<meta property="og:locale" content="en_US">', '<meta property="og:locale" content="en_US">' + "`n" + '<meta property="og:locale:alternate" content="ka_GE">')
  }
  if ($h -notmatch 'class="lang-switch"') {
    $sw = '<a class="lang-switch" href="' + (KaPath $p.path) + '" hreflang="ka" lang="ka" aria-label="Georgian version">KA</a>'
    $h = $h.Replace('<button class="menu-toggle"', $sw + "`n      " + '<button class="menu-toggle"')
  }
  WriteText $f $h
}

# ---------- 2. build Georgian pages ----------
foreach ($p in $pages) {
  $h = ReadText (Join-Path $root $p.file)
  $k = $p.key
  $kaUrl = $site + (KaPath $p.path)
  $title = T ('{S}title.' + $k)
  $desc = T ('{S}desc.' + $k)

  # head
  $h = $h.Replace('<html lang="en">', '<html lang="ka">')
  $h = [regex]::Replace($h, '<title>.*?</title>', { param($m) '<title>' + (Esc $title) + '</title>' })
  $h = SetMeta $h 'name' 'description' $desc
  $h = [regex]::Replace($h, '<link rel="canonical" href="[^"]*">', { param($m) '<link rel="canonical" href="' + $kaUrl + '">' })
  $h = SetMeta $h 'property' 'og:title' $title
  $h = SetMeta $h 'property' 'og:description' $desc
  $h = SetMeta $h 'property' 'og:url' $kaUrl
  $h = SetMeta $h 'property' 'og:image:alt' (T '{S}og.alt')
  $h = SetMeta $h 'name' 'twitter:title' $title
  $h = SetMeta $h 'name' 'twitter:description' $desc
  $h = $h.Replace('<meta property="og:locale" content="en_US">', '<meta property="og:locale" content="ka_GE">').Replace('<meta property="og:locale:alternate" content="ka_GE">', '<meta property="og:locale:alternate" content="en_US">')
  $h = [regex]::Replace($h, '(?s)<script>\(function\(\)\{var h=location\.hash;.*?</script>\s*', '')

  # structured data
  $ldMatch = [regex]::Match($h, '(?s)(<script type="application/ld\+json">)(.*?)(</script>)')
  if ($ldMatch.Success) {
    $j = $ldMatch.Groups[2].Value | ConvertFrom-Json
    foreach ($n in $j.'@graph') {
      $types = @($n.'@type')
      if ($types -contains 'Organization') { $n.description = T $orgDescKey }
      elseif ($types -contains 'WebSite') { $n.inLanguage = @('en', 'ka') }
      elseif ($types -contains 'BreadcrumbList') {
        $n.itemListElement[0].name = T '{S}crumb.home'
        $n.itemListElement[0].item = $site + '/ka/'
        $n.itemListElement[1].name = T ('{S}crumb.' + $k)
        $n.itemListElement[1].item = $kaUrl
      }
      elseif ($types -contains 'Service') {
        $en = $n.name
        $n.name = T $en
        $n.serviceType = T $en
        $n.description = T $svcDesc[$en]
      }
      elseif ($n.url -and $n.'@id' -like '*#webpage') {
        $n.'@id' = $kaUrl + '#webpage'
        $n.url = $kaUrl
        $n.name = $title
        $n.description = $desc
        $n.inLanguage = 'ka'
      }
    }
    $ldNew = $j | ConvertTo-Json -Depth 20 -Compress
    $h = $h.Replace($ldMatch.Value, $ldMatch.Groups[1].Value + $ldNew + $ldMatch.Groups[3].Value)
  }

  # body
  $bm = [regex]::Match($h, '(?s)(<body>)(.*)(</body>)')
  $body = $bm.Groups[2].Value
  $body = TranslateBody $body $k
  $body = $body.Replace('aria-label="Media Solution home"', 'aria-label="' + (Esc (T '{S}aria.home')) + '"')
  $body = $body.Replace('aria-label="Toggle navigation menu"', 'aria-label="' + (Esc (T '{S}aria.menu')) + '"')
  $body = [regex]::Replace($body, 'href="(/(?:about/|services/|careers/|contact/|privacy/|terms/|work/)?)"', { param($m) 'href="' + (KaPath $m.Groups[1].Value) + '"' })
  $enSwitch = '<a class="lang-switch" href="' + $p.path + '" hreflang="en" lang="en" aria-label="English version">EN</a>'
  $body = [regex]::Replace($body, '<a class="lang-switch"[^>]*>KA</a>', { param($m) $enSwitch })
  $h = $h.Substring(0, $bm.Index) + $bm.Groups[1].Value + $body + $bm.Groups[3].Value + $h.Substring($bm.Index + $bm.Length)

  $outFile = 'ka\' + $p.file
  WriteText (Join-Path $root $outFile) $h
}

# ---------- 3. sitemap with hreflang alternates ----------
$sm = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">' + "`n"
foreach ($p in ($pages | Where-Object { -not $_.noindex })) {
  $en = $site + $p.path
  $ka = $site + (KaPath $p.path)
  $alts = '    <xhtml:link rel="alternate" hreflang="en" href="' + $en + '"/>' + "`n" + '    <xhtml:link rel="alternate" hreflang="ka" href="' + $ka + '"/>' + "`n" + '    <xhtml:link rel="alternate" hreflang="x-default" href="' + $en + '"/>' + "`n"
  foreach ($u in @($en, $ka)) { $sm += "  <url>`n    <loc>$u</loc>`n    <lastmod>$today</lastmod>`n$alts  </url>`n" }
}
$sm += '</urlset>' + "`n"
WriteText (Join-Path $root 'sitemap.xml') $sm

# ---------- 4. keep tooling out of the published assets ----------
$ai = ReadText (Join-Path $root '.assetsignore')
if ($ai -notmatch '(?m)^tools$') { WriteText (Join-Path $root '.assetsignore') ($ai.TrimEnd() + "`ntools`n") }

"built $($pages.Count) Georgian pages"
if ($missing.Count -gt 0) { "UNTRANSLATED ($($missing.Count)):"; $missing | Sort-Object } else { 'no untranslated strings' }
