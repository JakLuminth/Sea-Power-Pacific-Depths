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
function Get-BlockValue([string]$Block, [string]$Key) {
    if ($null -eq $Block) { return $null }
    $match = [regex]::Match($Block, '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)')
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return $null
}

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$campaignRoot = Join-Path $repo 'mod\campaigns\pacific-depths-85'
$campaignPath = Join-Path $campaignRoot 'campaign.ini'
$locales = @('en','cn','ru','de','ja','es','fr','ko','vn')
$requiredBriefingHeadings = @{
    en = @('SITUATION','MISSION','EXECUTION','RULES OF ENGAGEMENT','FRIENDLY FORCES','SUPPORT')
    cn = @('态势','任务','执行','交战规则','友军','支援')
    ru = @('ОБСТАНОВКА','ЗАДАЧА','ПОРЯДОК ДЕЙСТВИЙ','ПРАВИЛА ПРИМЕНЕНИЯ ОРУЖИЯ','СВОИ','ОБЕСПЕЧЕНИЕ')
    de = @('LAGE','AUFTRAG','DURCHFÜHRUNG','EINSATZREGELN','EIGENE KRÄFTE','UNTERSTÜTZUNG')
    ja = @('状況','任務','実施要領','交戦規則','味方','支援')
    es = @('SITUACIÓN','MISIÓN','EJECUCIÓN','REGLAS DE ENFRENTAMIENTO','FUERZAS PROPIAS','APOYO')
    fr = @('SITUATION','MISSION','CONDUITE',"RÈGLES D'ENGAGEMENT",'FORCES AMIES','SOUTIEN')
    ko = @('상황','임무','실행','교전 규칙','우군','지원')
    vn = @('TÌNH HÌNH','NHIỆM VỤ','THỰC HIỆN','QUY TẮC GIAO CHIẾN','LỰC LƯỢNG TA','HỖ TRỢ')
}
$obsoleteFiles = @('player_task_force_roster.ini','commander_settings.ini')
$expectedPatrolCounts = @{
    '01_01_a_long_shadow' = 1
    '02_02_war_warning' = 1
    '03_03_ryukyu_screen' = 1
    '04_04_laperouse_gate' = 2
    '05_05_carrier_killer' = 2
    '06_06_through_kurils' = 2
    '07_07_bastion_watch' = 3
    '08_08_hammer_petropavlovsk' = 3
    '09_09_last_deterrent' = 3
    'O1_O1_cold_wake' = 1
    'O2_O2_picket_line' = 2
    'O3_O3_tenders_wake' = 3
}
$replenishmentStems = @('04_04_laperouse_gate','06_06_through_kurils','08_08_hammer_petropavlovsk')
$expectedPlayerTags = @('PD85_USS_Los_Angeles','PD85_USS_Drum','PD85_USS_San_Francisco')
$expectedPlayerTypes = @('usn_ssn_los_angeles','usn_ssn_sturgeon','usn_ssn_los_angeles')
$expectedPlayerVariants = @('Variant1','Variant28','Variant24')
$englishBriefingObjectives = @(
    'Shadow and classify K-525, then withdraw.',
    'Destroy the Victor III and withdraw.',
    'Break the Soviet ASW screen.',
    'Pass the strait and withdraw north.',
    'Destroy the screen command and withdraw.',
    'Penetrate Bussol Strait and withdraw north.',
    'Classify K-433 without firing, then withdraw.',
    'Ambush the offshore ASW command and replenishment group, then withdraw.',
    'Destroy K-433 and withdraw from the bastion.',
    'Classify the AGI, then withdraw without firing.',
    'Map K-525''s ASW pickets, then withdraw.',
    'Track Magadansky Komsomolets, then withdraw.'
)

if (-not (Require-File $campaignPath 'campaign definition')) { exit 1 }
if (-not (Require-File (Join-Path $repo 'mod\_info.ini') 'mod metadata')) { exit 1 }
if (-not (Require-File (Join-Path $campaignRoot 'enemy_theater_roster.ini') 'enemy DUG roster')) { exit 1 }
foreach ($obsoleteFile in $obsoleteFiles) {
    $obsoletePath = Join-Path $campaignRoot $obsoleteFile
    if (Test-Path -LiteralPath $obsoletePath -PathType Leaf) { Add-Failure "Obsolete Task Force file remains: $obsoletePath" }
}

$campaignText = Get-Content -Raw -LiteralPath $campaignPath
$campaignSections = Read-IniSections $campaignPath
$campaign = $campaignSections['Campaign']
$missions = $campaignSections['Missions']

if ((Get-IniValue $campaign 'Type') -ne 'Linear') { Add-Failure 'Campaign Type must be Linear.' }
if ((Get-IniValue $campaign 'Length') -ne '19') { Add-Failure 'Campaign Length must be 19 (7 events + 12 operations).' }
if ((Get-IniValue $missions 'NumberOfMissions') -ne '19') { Add-Failure 'Campaign NumberOfMissions must be 19.' }
if ($campaignSections.Contains('TaskForceMode')) { Add-Failure 'Campaign must not define a TaskForceMode section.' }
if ($campaignText -match '(?im)^TaskForceMode') { Add-Failure 'Campaign contains a TaskForceMode key.' }

foreach ($locale in $locales) {
    $section = $campaignSections["Language_$locale"]
    if ($null -eq $section) { Add-Failure "Campaign is missing Language_$locale."; continue }
    if ([string]::IsNullOrWhiteSpace((Get-IniValue $section 'Name'))) { Add-Failure "Campaign Language_$locale is missing Name." }
    if ([string]::IsNullOrWhiteSpace((Get-IniValue $section 'Description'))) { Add-Failure "Campaign Language_$locale is missing Description." }
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
    if ($Implemented -and $number -notin @('2','4','5','6','7','8','10','12','13','15','17','19')) { continue }
    $missionCount++
    $fileMatch = [regex]::Match($block, '(?m)^MissionFile=([^\r\n]+)')
    if (-not $fileMatch.Success) { Add-Failure "Mission$number has no MissionFile."; continue }
    $missionFile = Convert-CampaignPath $fileMatch.Groups[1].Value.Trim() $repo
    [void]$missionFiles.Add($missionFile)
    if (-not (Require-File $missionFile "Mission$number definition")) { continue }
    $missionText = Get-Content -Raw -LiteralPath $missionFile
    $missionSections = Read-IniSections $missionFile
    $missionStem = [System.IO.Path]::GetFileNameWithoutExtension($missionFile)
    $englishDescription = Get-IniValue $missionSections['Language_en'] 'Description'
    $englishBriefingText = $null
    foreach ($locale in $locales) {
        $languageSection = $missionSections["Language_$locale"]
        if ($null -eq $languageSection) { Add-Failure "Mission$number is missing Language_$locale."; continue }
        foreach ($key in @('Name','Description','MissionBriefingLeftPane')) {
            if ([string]::IsNullOrWhiteSpace((Get-IniValue $languageSection $key))) { Add-Failure "Mission$number Language_$locale is missing $key." }
        }
        $briefingMatch = [regex]::Match($languageSection, '(?m)^MissionBriefingLeftPane=(.+)$')
        if ($briefingMatch.Success) {
            $expectedBriefingFragment = ('missions/' + $missionStem + '_briefing/').Replace('/', '[\\/]')
            if ($briefingMatch.Groups[1].Value -notmatch $expectedBriefingFragment) { Add-Failure "Mission$number briefing for $locale references another operation." }
            $briefingPath = Convert-CampaignPath $briefingMatch.Groups[1].Value.Trim() $repo
            if (Require-File $briefingPath "Mission$number briefing $locale") {
                try {
                    $briefingRaw = Get-Content -Raw -LiteralPath $briefingPath
                    [void][xml]$briefingRaw
                    if ($briefingRaw.Contains([string][char]0xFFFD)) { Add-Failure "Mission$number $locale briefing contains a replacement character." }
                    foreach ($heading in $requiredBriefingHeadings[$locale]) {
                        if ($briefingRaw -notmatch ('(?m)^' + [regex]::Escape($heading) + '\r?$')) { Add-Failure "Mission$number $locale briefing is missing military-sim section '$heading'." }
                    }
                    if ($locale -eq 'en') { $englishBriefingText = $briefingRaw }
                    else {
                        if ($briefingRaw -eq $englishBriefingText) { Add-Failure "Mission$number $locale briefing duplicates the English briefing." }
                        foreach ($englishObjective in $englishBriefingObjectives) {
                            if ($briefingRaw.Contains($englishObjective)) { Add-Failure "Mission$number $locale briefing retains English objective text." }
                        }
                    }
                } catch { Add-Failure "Invalid briefing XML for Mission$number ($locale): $briefingPath" }
            }
        }
        if ($locale -ne 'en' -and (Get-IniValue $languageSection 'Description') -eq $englishDescription) { Add-Failure "Mission$number Language_$locale duplicates the English Description." }
        if ($locale -ne 'en' -and (Get-IniValue $languageSection 'Name') -match '^(Mission|Einsatz|Misión|Mission\s*:|Nhiệm vụ)\s*:?[ ]+[A-Z0-9O]+$') { Add-Failure "Mission$number Language_$locale uses a locale-prefix-only Name." }
    }
    if ($missionText -match '(?im)^TaskForceMode') { Add-Failure "Mission$number contains a TaskForceMode key." }
    if ($missionText -notmatch '(?m)^\[Taskforce1Submarine\d+\]') { Add-Failure "Mission$number has no player submarine slot." }
    if ($missionText -match '(?m)^\[Taskforce1(Vessel|Aircraft|LandUnit)\d+\]') { Add-Failure "Mission$number exposes a non-submarine player slot." }
    $missionStem = [System.IO.Path]::GetFileNameWithoutExtension($missionFile)
    if (-not $expectedPatrolCounts.ContainsKey($missionStem)) {
        Add-Failure "Mission$number uses an unknown authored mission stem: $missionStem"
    } else {
        $expectedCount = [int]$expectedPatrolCounts[$missionStem]
        $declaredCount = Get-IniValue $missionSections['Mission'] 'NumberOfTaskforce1Submarines'
        if ($declaredCount -ne [string]$expectedCount) { Add-Failure "Mission$number must declare $expectedCount player submarine(s), found '$declaredCount'." }
        $playerSlots = @(Get-PlayerSubmarineSections $missionText)
        if ($playerSlots.Count -ne $expectedCount) { Add-Failure "Mission$number must contain $expectedCount authored player submarine slot(s), found $($playerSlots.Count)." }
        $deploymentBlock = Get-SectionBlock $missionText 'Zone_PlayerDeployment'
        $zoneWidth = 0.0
        $zoneHeight = 0.0
        [void][double]::TryParse((Get-BlockValue $deploymentBlock 'WidthNm'), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$zoneWidth)
        [void][double]::TryParse((Get-BlockValue $deploymentBlock 'HeightNm'), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$zoneHeight)
        for ($slotIndex = 0; $slotIndex -lt $playerSlots.Count; $slotIndex++) {
            $slot = $playerSlots[$slotIndex]
            $slotText = $slot.Groups[1].Value
            $slotNumberMatch = [regex]::Match($slot.Value, '^\[Taskforce1Submarine(\d+)\]')
            $slotNumber = if ($slotNumberMatch.Success) { [int]$slotNumberMatch.Groups[1].Value } else { -1 }
            $expectedSlotNumber = $slotIndex + 1
            if ($slotNumber -ne $expectedSlotNumber) { Add-Failure "Mission$number player slots must be numbered consecutively from 1." }
            $expectedTag = $expectedPlayerTags[$slotIndex]
            $expectedType = $expectedPlayerTypes[$slotIndex]
            $expectedVariant = $expectedPlayerVariants[$slotIndex]
            if ((Get-BlockValue $slotText 'Type') -ne $expectedType) { Add-Failure "Mission$number slot $expectedSlotNumber must use $expectedType." }
            if ((Get-BlockValue $slotText 'VariantReference') -ne $expectedVariant) { Add-Failure "Mission$number slot $expectedSlotNumber must use $expectedVariant." }
            if ((Get-BlockValue $slotText 'CampaignTag') -ne $expectedTag) { Add-Failure "Mission$number slot $expectedSlotNumber must use CampaignTag=$expectedTag." }
            if ((Get-BlockValue $slotText 'SetSelected') -ne $(if ($slotIndex -eq 0) { 'True' } else { $null })) { Add-Failure "Mission$number slot $expectedSlotNumber has an invalid SetSelected value." }
            $position = Get-BlockValue $slotText 'RelativePositionInNM'
            if ([string]::IsNullOrWhiteSpace($position) -or $position -notmatch '^-?\d+(?:\.\d+)?(?:,-?\d+(?:\.\d+)?|,[^,\r\n]+),-?\d+(?:\.\d+)?$') { Add-Failure "Mission$number slot $expectedSlotNumber has invalid RelativePositionInNM geometry: '$position'." }
            $positionMatch = [regex]::Match($position, '^(-?\d+(?:\.\d+)?),[^,\r\n]+,(-?\d+(?:\.\d+)?)$')
            if ($positionMatch.Success -and $zoneWidth -gt 0 -and $zoneHeight -gt 0) {
                $relativeX = [double]::Parse($positionMatch.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
                $relativeY = [double]::Parse($positionMatch.Groups[2].Value, [System.Globalization.CultureInfo]::InvariantCulture)
                if ([Math]::Abs($relativeX) -gt ($zoneWidth / 2.0) -or [Math]::Abs($relativeY) -gt ($zoneHeight / 2.0)) { Add-Failure "Mission$number slot $expectedSlotNumber spawns outside Zone_PlayerDeployment ($position vs ${zoneWidth}x${zoneHeight}NM)." }
            }
            $heading = Get-BlockValue $slotText 'Heading'
            if ([string]::IsNullOrWhiteSpace($heading) -or $heading -notmatch '^-?\d+(?:\.\d+)?$') { Add-Failure "Mission$number slot $expectedSlotNumber has an invalid Heading." }
            if ([string]::IsNullOrWhiteSpace((Get-BlockValue $slotText 'Waypoints'))) { Add-Failure "Mission$number slot $expectedSlotNumber has no authored Waypoints." }
            if ((Get-BlockValue $slotText 'UnlimitedFuel') -ne 'False') { Add-Failure "Mission$number slot $expectedSlotNumber must set UnlimitedFuel=False." }
            if ((Get-BlockValue $slotText 'TowedArrayDeployed') -ne 'True') { Add-Failure "Mission$number slot $expectedSlotNumber must set TowedArrayDeployed=True." }
            $hasRearm = $slotText -match '(?m)^CampaignRearm=True(?:\r?$)'
            $hasRepair = $slotText -match '(?m)^CampaignRepair=True(?:\r?$)'
            $shouldReplenish = $missionStem -in $replenishmentStems
            if ($shouldReplenish -and (-not $hasRearm -or -not $hasRepair)) { Add-Failure "Mission$number slot $expectedSlotNumber must have CampaignRearm=True and CampaignRepair=True." }
            if (-not $shouldReplenish -and ($hasRearm -or $hasRepair)) { Add-Failure "Mission$number must not replenish player boats at this interval." }
        }
    }
    if ($missionText -notmatch '(?m)^\[Taskforce1_Objectives\]') { Add-Failure "Mission$number has no Taskforce1_Objectives section." }
    if ($missionText -notmatch '(?m)^\[Zones\]') { Add-Failure "Mission$number has no deployment/spawn zones." }
    if ($missionText -notmatch '(?ms)^\[Zone_PlayerDeployment\]\s*.*?^Type=Deployment') { Add-Failure "Mission$number has no player deployment zone." }
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
}

$declaredCampaignVariables = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($allMissionFile in Get-ChildItem -LiteralPath (Join-Path $campaignRoot 'missions') -File -Filter '*.ini') {
    $allMissionText = Get-Content -Raw -LiteralPath $allMissionFile.FullName
    $variableBlock = Get-SectionBlock $allMissionText 'CampaignVariables'
    if ($null -eq $variableBlock) { continue }
    foreach ($line in ($variableBlock -split "`r?`n")) {
        if ($line -match '^\s*(PD85_[A-Za-z0-9_]+)=False\s*$') { [void]$declaredCampaignVariables.Add($Matches[1]) }
    }
}
foreach ($file in $missionFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
    $text = Get-Content -Raw -LiteralPath $file
    foreach ($reference in [regex]::Matches($text, '(?m)^(?:Action_VariableSet|SpawnByVariableAND)=(PD85_[A-Za-z0-9_]+),')) {
        $variable = $reference.Groups[1].Value
        if (-not $declaredCampaignVariables.Contains($variable)) { Add-Failure "Undefined PD85 variable read/write in $file`: $variable" }
    }
}
$expectedEventCount = if ($VerticalSlice -or $Implemented) { 2 } else { 7 }
$expectedMissionCount = if ($VerticalSlice) { 2 } elseif ($Implemented) { 12 } else { 12 }
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
    $objectiveBlock = Get-SectionBlock $text 'Taskforce1_Objectives'
    $objectiveKeys = Get-IniKeys ([System.Collections.Generic.List[string]]($objectiveBlock -split "`r?`n"))
    foreach ($action in [regex]::Matches($text, '(?m)^Action_Objectives(?:Completed|Failed|Cancel)=([^\r\n]+)')) {
        foreach ($objective in ($action.Groups[1].Value -split ',')) {
            $name = $objective.Trim()
            if ($name -and -not $objectiveKeys.Contains($name)) { Add-Failure "Unknown objective '$name' referenced in $file" }
        }
    }
    foreach ($slot in [regex]::Matches($text, '(?ms)^\[Taskforce2(?:Vessel|Submarine|Aircraft)\d+\]\s*(.*?)(?=^\[[^\r\n\]]+\]|\z)')) {
        $slotText = $slot.Groups[1].Value
        if ($slotText -match '(?m)^DynamicGenerationSlot=True' -and $slotText -notmatch '(?m)^DynamicGenerationRoster=Taskforce2') { Add-Failure "Dynamic enemy slot lacks Taskforce2 roster in $file" }
        if ($slotText -match '(?m)^DynamicGenerationSlot=True' -and $slotText -notmatch '(?m)^DynamicGenerationSpawnZone=') { Add-Failure "Dynamic enemy slot lacks a spawn zone in $file" }
    }
    foreach ($withdrawal in [regex]::Matches($text, '(?ms)^\[Trigger\d+\]\s*Name=Withdraw.*?(?=^\[[^\r\n\]]+\]|\z)')) {
        if ($withdrawal.Value -notmatch '(?m)^Disabled=True') { Add-Failure "Withdrawal trigger must begin disabled in $file" }
        if ($withdrawal.Value -notmatch '(?m)^Action_EndMission=True') { Add-Failure "Withdrawal trigger must end the mission in $file" }
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
Write-Output 'PASS: authored-linear graph, locale parity, briefing/event XML, submarine patrol continuity, replenishment schedule, DUG references, variables, and installed IDs.'
exit 0
