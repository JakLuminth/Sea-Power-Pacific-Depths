[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\Sea Power',
    [switch]$VerticalSlice,
    [switch]$Implemented
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) { [void]$failures.Add($Message) }
function Add-Warning([string]$Message) { [void]$warnings.Add($Message) }
function Require-File([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Failure("Missing $Description`: $Path")
        return $false
    }
    return $true
}
function Convert-CampaignPath([string]$Path, [string]$Root) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $normalized = $Path.Replace('/', '\')
    if ($normalized.StartsWith('campaigns\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return Join-Path $Root (Join-Path 'mod' $normalized)
    }
    return $null
}
function Read-IniSections([string]$Path) {
    $result = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $result }
    $section = ''
    foreach ($raw in Get-Content -LiteralPath $Path) {
        $line = $raw.Trim()
        if ($line -match '^\[([^\]]+)\]$') {
            $section = $Matches[1]
            if (-not $result.Contains($section)) { $result[$section] = [System.Collections.Generic.List[string]]::new() }
            continue
        }
        if ($section -and $line -and -not $line.StartsWith(';') -and -not $line.StartsWith('#')) {
            [void]$result[$section].Add($line)
        }
    }
    return $result
}
function Get-IniValue([System.Collections.Generic.List[string]]$Lines, [string]$Key) {
    if ($null -eq $Lines) { return $null }
    foreach ($line in $Lines) {
        if ($line -match ('^' + [regex]::Escape($Key) + '=(.*)$')) { return $Matches[1] }
    }
    return $null
}
function Get-IniKeys([System.Collections.Generic.List[string]]$Lines) {
    $keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if ($null -eq $Lines) { return $keys }
    foreach ($line in $Lines) {
        if ($line -match '^([^=]+)=') { [void]$keys.Add($Matches[1]) }
    }
    return $keys
}
function Get-SectionBlock([string]$Text, [string]$SectionName) {
    $escaped = [regex]::Escape($SectionName)
    $match = [regex]::Match($Text, '(?ms)^\[' + $escaped + '\]\s*(.*?)(?=^\[[^\r\n\]]+\]|\z)')
    if ($match.Success) { return $match.Groups[1].Value }
    return $null
}
function Get-TypesFromMission([string]$Text) {
    $types = [System.Collections.Generic.List[string]]::new()
    $sectionPattern = '(?ms)^\[(Taskforce\d+(?:Submarine|Vessel|Aircraft|LandUnit)\d+|Neutral(?:Vessel|Biologic)\d+)\]\s*(.*?)(?=^\[[^\r\n\]]+\]|\z)'
    foreach ($section in [regex]::Matches($Text, $sectionPattern)) {
        $typeMatch = [regex]::Match($section.Groups[2].Value, '(?m)^Type=([^\r\n;]+)')
        if ($typeMatch.Success) { [void]$types.Add($typeMatch.Groups[1].Value.Trim()) }
    }
    return $types
}
function Get-PlayerSubmarineSections([string]$Text) {
    return [regex]::Matches($Text, '(?ms)^\[Taskforce1Submarine\d+\]\s*(.*?)(?=^\[[^\r\n\]]+\]|\z)')
}

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$campaignRoot = Join-Path $repo 'mod\campaigns\pacific-depths-85'
$campaignPath = Join-Path $campaignRoot 'campaign.ini'
$rosterPath = Join-Path $campaignRoot 'player_task_force_roster.ini'
$locales = @('en','cn','ru','de','ja','es','fr','ko','vn')
$requiredPlayerTypes = @('usn_ssn_los_angeles','usn_ssn_sturgeon')

if (-not (Require-File $campaignPath 'campaign definition')) { exit 1 }
if (-not (Require-File $rosterPath 'player roster')) { exit 1 }
if (-not (Require-File (Join-Path $repo 'mod\_info.ini') 'mod metadata')) { exit 1 }

$campaignText = Get-Content -Raw -LiteralPath $campaignPath
$campaignSections = Read-IniSections $campaignPath
$campaign = $campaignSections['Campaign']
$tfm = $campaignSections['TaskForceMode']
$missions = $campaignSections['Missions']

if ((Get-IniValue $campaign 'Type') -ne 'Linear') { Add-Failure 'Campaign Type must be Linear.' }
if ((Get-IniValue $campaign 'Length') -ne '19') { Add-Failure 'Campaign Length must be 19 (7 events + 12 operations).' }
if ((Get-IniValue $missions 'NumberOfMissions') -ne '19') { Add-Failure 'Campaign NumberOfMissions must be 19.' }
if ((Get-IniValue $tfm 'Enabled') -ne 'True') { Add-Failure 'TaskForceMode must be enabled.' }
if ((Get-IniValue $tfm 'TaskForceRequireFlagship') -ne 'True') { Add-Failure 'TaskForceRequireFlagship must be True.' }
if ((Get-IniValue $tfm 'ShipIncludesAirwing') -ne 'False') { Add-Failure 'ShipIncludesAirwing must be False.' }

foreach ($locale in $locales) {
    $section = $campaignSections["Language_$locale"]
    if ($null -eq $section) { Add-Failure "Campaign is missing Language_$locale."; continue }
    if ([string]::IsNullOrWhiteSpace((Get-IniValue $section 'Name'))) { Add-Failure "Campaign Language_$locale is missing Name." }
    if ([string]::IsNullOrWhiteSpace((Get-IniValue $section 'Description'))) { Add-Failure "Campaign Language_$locale is missing Description." }
}

$rosterSections = Read-IniSections $rosterPath
$allowedSubs = $rosterSections['AllowedSubmarines']
foreach ($type in $requiredPlayerTypes) {
    if ($null -eq $allowedSubs -or -not ($allowedSubs | Where-Object { $_ -match ('^' + [regex]::Escape($type) + '=') })) {
        Add-Failure "Player roster is missing $type in AllowedSubmarines."
    }
}
foreach ($emptySection in @('AllowedVessels','AllowedHelicopters','AllowedAircraft')) {
    foreach ($line in $rosterSections[$emptySection]) {
        if ($line -match '=\s*\S') { Add-Failure "Player roster must not permit non-submarine units ($emptySection): $line" }
    }
}

$missionMatches = [regex]::Matches($campaignText, '(?ms)^\[Mission(\d+)\]\s*(.*?)(?=^\[Mission\d+\]\s*|\z)')
$eventCount = 0
$missionCount = 0
$missionFiles = [System.Collections.Generic.List[string]]::new()
foreach ($match in $missionMatches) {
    $number = $match.Groups[1].Value
    $block = $match.Groups[2].Value
    $typeMatch = [regex]::Match($block, '(?m)^Type=([^\r\n]+)')
    if (-not $typeMatch.Success) { Add-Failure "Mission$number has no Type."; continue }
    $type = $typeMatch.Groups[1].Value.Trim()
    if ($type -eq 'FreeEvent') {
        if ($VerticalSlice -and $number -notin @('1','3')) { continue }
        if ($Implemented -and $number -notin @('1','3')) { continue }
        $eventCount++
        foreach ($locale in $locales) {
            if ($block -notmatch ('(?m)^Name_' + [regex]::Escape($locale) + '=')) { Add-Failure "Mission$number event missing Name_$locale." }
            $eventPathMatch = [regex]::Match($block, '(?m)^FilePath_' + [regex]::Escape($locale) + '=([^\r\n]+)')
            if (-not $eventPathMatch.Success) { Add-Failure "Mission$number event missing FilePath_$locale."; continue }
            $eventPath = Convert-CampaignPath $eventPathMatch.Groups[1].Value.Trim() $repo
            if ($null -eq $eventPath) { Add-Failure "Mission$number event $locale has an invalid campaign path."; continue }
            if (Require-File $eventPath "Mission$number event $locale") {
                try { [void][xml](Get-Content -Raw -LiteralPath $eventPath) } catch { Add-Failure "Invalid event XML for Mission$number ($locale): $eventPath" }
            }
        }
        continue
    }
    if ($type -ne 'Mission') { Add-Failure "Mission$number has unsupported Type=$type."; continue }
    if ($VerticalSlice -and $number -notin @('2','4')) { continue }
    if ($Implemented -and $number -notin @('2','4','5','6','7','8','10','12','13','15')) { continue }
    $missionCount++
    $fileMatch = [regex]::Match($block, '(?m)^MissionFile=([^\r\n]+)')
    if (-not $fileMatch.Success) { Add-Failure "Mission$number has no MissionFile."; continue }
    $missionFile = Convert-CampaignPath $fileMatch.Groups[1].Value.Trim() $repo
    [void]$missionFiles.Add($missionFile)
    if (-not (Require-File $missionFile "Mission$number definition")) { continue }
    $missionText = Get-Content -Raw -LiteralPath $missionFile
    $missionSections = Read-IniSections $missionFile
    foreach ($locale in $locales) {
        $languageSection = $missionSections["Language_$locale"]
        if ($null -eq $languageSection) { Add-Failure "Mission$number is missing Language_$locale."; continue }
        foreach ($key in @('Name','Description','MissionBriefingLeftPane')) {
            if ([string]::IsNullOrWhiteSpace((Get-IniValue $languageSection $key))) { Add-Failure "Mission$number Language_$locale is missing $key." }
        }
        $briefingMatch = [regex]::Match($languageSection, '(?m)^MissionBriefingLeftPane=(.+)$')
        if ($briefingMatch.Success) {
            $briefingPath = Convert-CampaignPath $briefingMatch.Groups[1].Value.Trim() $repo
            if (Require-File $briefingPath "Mission$number briefing $locale") {
                try { [void][xml](Get-Content -Raw -LiteralPath $briefingPath) } catch { Add-Failure "Invalid briefing XML for Mission$number ($locale): $briefingPath" }
            }
        }
    }
    if ($missionText -notmatch '(?m)^\[Taskforce1Submarine\d+\]') { Add-Failure "Mission$number has no player submarine slot." }
    if ($missionText -match '(?m)^\[Taskforce1(Vessel|Aircraft|LandUnit)\d+\]') { Add-Failure "Mission$number exposes a non-submarine player slot." }
    foreach ($slot in (Get-PlayerSubmarineSections $missionText)) {
        $slotText = $slot.Groups[1].Value
        $typeMatch = [regex]::Match($slotText, '(?m)^Type=([^\r\n]+)')
        if (-not $typeMatch.Success -or $typeMatch.Groups[1].Value.Trim() -notmatch '^usn_ssn_') { Add-Failure "Mission$number player slot is not a USN attack submarine." }
        if ($slotText -notmatch '(?m)^TaskForceModeReplacedUnitIndex=\d+') { Add-Failure "Mission$number player submarine lacks ReplacedUnitIndex." }
    }
    if ($missionText -notmatch '(?m)^\[Taskforce1_Objectives\]') { Add-Failure "Mission$number has no Taskforce1_Objectives section." }
    if ($missionText -notmatch '(?m)^\[Zones\]') { Add-Failure "Mission$number has no deployment/spawn zones." }
    $types = Get-TypesFromMission $missionText
    if ($GameRoot -and (Test-Path -LiteralPath $GameRoot -PathType Container)) {
        $unitDirs = @('vessels','land_units','aircraft','biologic') | ForEach-Object { Join-Path $GameRoot ("Sea Power_Data\StreamingAssets\original\" + $_) }
        $knownTypes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($unitDir in $unitDirs) {
            if (Test-Path -LiteralPath $unitDir -PathType Container) {
                foreach ($file in Get-ChildItem -LiteralPath $unitDir -File -Filter '*.ini') {
                    $base = $file.BaseName -replace '_variants$',''
                    [void]$knownTypes.Add($base)
                }
            }
        }
        foreach ($unitType in $types) {
            if (-not $knownTypes.Contains($unitType)) { Add-Failure "Mission$number references missing installed unit ID: $unitType" }
        }
    } else {
        Add-Warning "GameRoot not found; installed unit ID checks skipped."
    }
    if ($number -in @('2','4')) {
        if ($block -notmatch '(?m)^TaskForceModeIncludesSubmarine=True') { Add-Failure "Mission$number must include submarines." }
        if ($block -notmatch '(?m)^TaskForceModeIncludesAirwing=False') { Add-Failure "Mission$number must exclude air wings." }
        if ($block -notmatch '(?m)^TaskForceModeRequiredUnitType=Submarine') { Add-Failure "Mission$number must request submarine-only builder mode." }
    }
}
$expectedEventCount = if ($VerticalSlice -or $Implemented) { 2 } else { 7 }
$expectedMissionCount = if ($VerticalSlice) { 2 } elseif ($Implemented) { 10 } else { 12 }
if ($eventCount -ne $expectedEventCount) { Add-Failure "Expected $expectedEventCount timeline events, found $eventCount." }
if ($missionCount -ne $expectedMissionCount) { Add-Failure "Expected $expectedMissionCount operations, found $missionCount." }

$m1Path = Join-Path $campaignRoot 'missions\01_01_a_long_shadow.ini'
if (Test-Path -LiteralPath $m1Path -PathType Leaf) {
    $m1Text = Get-Content -Raw -LiteralPath $m1Path
    foreach ($variable in @('PD85_O1_AGITracked','PD85_O2_PicketsMapped','PD85_O3_TenderTracked','PD85_M8_ASWSuppressed')) {
        if ($m1Text -notmatch ('(?m)^' + [regex]::Escape($variable) + '=')) { Add-Failure "M1 does not declare campaign variable $variable." }
    }
    if ($m1Text -match '(?m)^PD85_[^=]+=PD85_') { Add-Failure 'M1 campaign variables must use shipped Name=False initialization syntax.' }
    if ($m1Text -notmatch '(?ms)^\[Trigger4\]\s*.*?^Disabled=True') { Add-Failure 'M1 withdrawal trigger must begin disabled.' }
    if ($m1Text -match '(?m)^DynamicGenerationFormation=Formation_') { Add-Failure 'M1 dynamic formation reference must omit the Formation_ section prefix.' }
}
$m2Path = Join-Path $campaignRoot 'missions\02_02_war_warning.ini'
if (Test-Path -LiteralPath $m2Path -PathType Leaf) {
    $m2Text = Get-Content -Raw -LiteralPath $m2Path
    if ($m2Text -notmatch '(?ms)^\[Trigger4\]\s*.*?^Disabled=True') { Add-Failure 'M2 withdrawal trigger must begin disabled.' }
    if ($m2Text -match '(?m)^DynamicGenerationFormation=Formation_') { Add-Failure 'M2 dynamic formation reference must omit the Formation_ section prefix.' }
}
$enemyRosterPath = Join-Path $campaignRoot 'enemy_theater_roster.ini'
if (Test-Path -LiteralPath $enemyRosterPath -PathType Leaf) {
    $enemyRoster = Get-Content -Raw -LiteralPath $enemyRosterPath
    if ($enemyRoster -match '(?m)^wp_ssn_alfa=.*\bVariant1\b') { Add-Failure 'Enemy roster must exclude date-invalid Alfa Variant1.' }
    if ($enemyRoster -match '(?m)^wp_ss_foxtrot=.*\bVariant23\b') { Add-Failure 'Enemy roster must exclude date-invalid Foxtrot Variant23.' }
}
foreach ($file in $missionFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
    $text = Get-Content -Raw -LiteralPath $file
    foreach ($action in [regex]::Matches($text, '(?m)^(?:Action_VariableSet|SpawnByVariableAND)=([^\r\n]+)')) {
        $value = $action.Groups[1].Value
        if ($value -notmatch 'PD85_(?:O1_AGITracked|O2_PicketsMapped|O3_TenderTracked|M8_ASWSuppressed)') {
            Add-Failure "Unknown campaign variable reference in $file`: $value"
        }
    }
}

Write-Output "Pacific Depths '85 static validation"
Write-Output "Repository: $repo"
Write-Output "Operations: $missionCount; timeline events: $eventCount; locales: $($locales.Count); vertical slice: $VerticalSlice"
foreach ($warning in $warnings) { Write-Warning $warning }
if ($failures.Count -gt 0) {
    Write-Error ("FAILED with {0} issue(s):`n - {1}" -f $failures.Count, ($failures -join "`n - "))
    exit 1
}
Write-Output 'PASS: campaign graph, locale parity, briefing/event XML, submarine-only player slots, variables, and installed IDs.'
exit 0
