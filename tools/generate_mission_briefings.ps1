param([string]$CampaignRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'mod\campaigns\pacific-depths-85'))

$missions = @(
    @{ File='01_01_a_long_shadow'; Code='01'; Title='A LONG SHADOW'; Objective='Shadow and classify K-525, then withdraw.' },
    @{ File='02_02_war_warning'; Code='02'; Title='WAR WARNING'; Objective='Destroy the Victor III and withdraw.' },
    @{ File='03_03_ryukyu_screen'; Code='03'; Title='RYUKYU SCREEN'; Objective='Break the Soviet ASW screen.' },
    @{ File='04_04_laperouse_gate'; Code='04'; Title='LA PEROUSE GATE'; Objective='Pass the strait and withdraw north.' },
    @{ File='05_05_carrier_killer'; Code='05'; Title='CARRIER KILLER'; Objective='Destroy the screen command and withdraw.' },
    @{ File='06_06_through_kurils'; Code='06'; Title='THROUGH THE KURILS'; Objective='Penetrate Bussol Strait and withdraw north.' },
    @{ File='07_07_bastion_watch'; Code='07'; Title='BASTION WATCH'; Objective='Classify K-433 without firing, then withdraw.' },
    @{ File='08_08_hammer_petropavlovsk'; Code='08'; Title='HAMMER AT PETROPAVLOVSK'; Objective='Ambush the offshore ASW command and replenishment group, then withdraw.' },
    @{ File='09_09_last_deterrent'; Code='09'; Title='THE LAST DETERRENT'; Objective='Destroy K-433 and withdraw from the bastion.' },
    @{ File='O1_O1_cold_wake'; Code='O1'; Title='COLD WAKE'; Objective='Classify the AGI, then withdraw without firing.' },
    @{ File='O2_O2_picket_line'; Code='O2'; Title='THE PICKET LINE'; Objective='Map K-525''s ASW pickets, then withdraw.' },
    @{ File='O3_O3_tenders_wake'; Code='O3'; Title='THE TENDER''S WAKE'; Objective='Track Magadansky Komsomolets, then withdraw.' }
)

$locales = [ordered]@{
    en = @{ Header='MISSION'; Situation='SITUATION'; Mission='MISSION'; Friendly='FRIENDLY'; Prefix=''; SituationText='Submerged operations in the Pacific require stealth and patience.'; Close='USS Los Angeles must survive.' }
    cn = @{ Header='任务'; Situation='态势'; Mission='任务'; Friendly='友军'; Prefix='第'; Suffix='号任务'; SituationText='太平洋水下行动需要隐蔽和耐心。'; ObjectiveText='完成指定目标后撤离。'; DescriptionText='在太平洋完成潜艇任务并安全撤离。'; Close='洛杉矶号必须生还。' }
    ru = @{ Header='ЗАДАНИЕ'; Situation='ОБСТАНОВКА'; Mission='ЗАДАЧА'; Friendly='СВОИ'; Prefix='Задание '; Suffix=': Тихоокеанский дозор'; SituationText='Подводная операция в Тихом океане требует скрытности и терпения.'; ObjectiveText='Выполните поставленную задачу и отходите.'; DescriptionText='Выполните подводную задачу в Тихом океане и отходите.'; Close='USS Los Angeles должна выжить.' }
    de = @{ Header='EINSATZ'; Situation='LAGE'; Mission='AUFTRAG'; Friendly='EIGENE KRÄFTE'; Prefix='Einsatz '; Suffix=': Pazifikpatrouille'; SituationText='Unterwasseroperationen im Pazifik verlangen Tarnung und Geduld.'; ObjectiveText='Erfüllen Sie den Auftrag und ziehen Sie sich zurück.'; DescriptionText='Erfüllen Sie den U-Boot-Auftrag im Pazifik und ziehen Sie sich zurück.'; Close='USS Los Angeles muss überleben.' }
    ja = @{ Header='任務'; Situation='状況'; Mission='任務'; Friendly='味方'; Prefix='任務'; Suffix=''; SituationText='太平洋での潜水艦作戦には隠密行動と忍耐が必要です。'; ObjectiveText='指定目標を達成してから離脱してください。'; DescriptionText='太平洋で潜水艦任務を遂行し、安全に離脱してください。'; Close='ロサンゼルスは生還しなければならない。' }
    es = @{ Header='MISIÓN'; Situation='SITUACIÓN'; Mission='MISIÓN'; Friendly='FUERZAS PROPIAS'; Prefix='Misión '; Suffix=': Patrulla del Pacífico'; SituationText='Las operaciones submarinas en el Pacífico exigen sigilo y paciencia.'; ObjectiveText='Cumpla el objetivo asignado y retírese.'; DescriptionText='Cumpla la misión submarina en el Pacífico y retírese.'; Close='USS Los Angeles debe sobrevivir.' }
    fr = @{ Header='MISSION'; Situation='SITUATION'; Mission='MISSION'; Friendly='FORCES AMIES'; Prefix='Mission '; Suffix=': Patrouille du Pacifique'; SituationText='Les opérations sous-marines dans le Pacifique exigent discrétion et patience.'; ObjectiveText='Accomplissez l''objectif désigné puis repliez-vous.'; DescriptionText='Accomplissez la mission sous-marine dans le Pacifique puis repliez-vous.'; Close='L''USS Los Angeles doit survivre.' }
    ko = @{ Header='임무'; Situation='상황'; Mission='임무'; Friendly='아군'; Prefix='임무 '; Suffix=''; SituationText='태평양 잠수함 작전에는 은밀함과 인내가 필요합니다.'; ObjectiveText='지정된 목표를 달성한 뒤 철수하십시오.'; DescriptionText='태평양에서 잠수함 임무를 수행하고 안전하게 철수하십시오.'; Close='로스앤젤레스함은 반드시 생존해야 합니다.' }
    vn = @{ Header='NHIỆM VỤ'; Situation='TÌNH HÌNH'; Mission='NHIỆM VỤ'; Friendly='LỰC LƯỢNG TA'; Prefix='Nhiệm vụ '; Suffix=': Tuần tra Thái Bình Dương'; SituationText='Hoạt động tàu ngầm ở Thái Bình Dương đòi hỏi bí mật và kiên nhẫn.'; ObjectiveText='Hoàn thành mục tiêu được giao rồi rút lui.'; DescriptionText='Hoàn thành nhiệm vụ tàu ngầm ở Thái Bình Dương rồi rút lui.'; Close='USS Los Angeles phải sống sót.' }
}

foreach ($mission in $missions) {
    $iniPath = Join-Path $CampaignRoot ('missions\' + $mission.File + '.ini')
    $briefDir = Join-Path $CampaignRoot ('missions\' + $mission.File + '_briefing')
    New-Item -ItemType Directory -Force -Path $briefDir | Out-Null
    foreach ($locale in $locales.Keys) {
        $labels = $locales[$locale]
        $title = if ($locale -eq 'en') { $mission.Title } else { $labels.Prefix + $mission.Code + $labels.Suffix }
        $objective = if ($locale -eq 'en') { $mission.Objective } else { $labels.ObjectiveText }
        $body = "{0}`n{1}`n`n{2}`n{3}`n`n{4}`n{5}`n`n{6}`n{7}" -f $labels.Header, $title, $labels.Situation, $labels.SituationText, $labels.Mission, $objective, $labels.Friendly, $labels.Close
        $escaped = [System.Security.SecurityElement]::Escape($body)
        $xml = '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"><Viewbox Stretch="Uniform"><Border Width="1200" Height="760" Background="#101922" Padding="44"><StackPanel TextElement.Foreground="#D8DCE0" TextElement.FontFamily="Roboto"><TextBlock TextWrapping="Wrap" FontSize="18" LineHeight="28">' + $escaped + '</TextBlock></StackPanel></Border></Viewbox></Grid>'
        Set-Content -LiteralPath (Join-Path $briefDir ('BriefingText_' + $locale + '.xml')) -Value $xml -Encoding utf8NoBOM
    }
    $section = ''
    $rewritten = foreach ($line in Get-Content -LiteralPath $iniPath) {
        if ($line -match '^\[Language_(.+)\]$') { $section = $Matches[1] }
        if ($line -match '^MissionBriefingLeftPane=') { 'MissionBriefingLeftPane=campaigns/pacific-depths-85/missions/' + $mission.File + '_briefing/BriefingText_' + $section + '.xml' }
        elseif ($section -ne 'en' -and $line -match '^Name=') { 'Name=' + $locales[$section].Prefix + $mission.Code + $locales[$section].Suffix }
        elseif ($section -ne 'en' -and $line -match '^Description=') { 'Description=' + $locales[$section].DescriptionText }
        else { $line }
    }
    Set-Content -LiteralPath $iniPath -Value $rewritten -Encoding utf8NoBOM
}
