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

# Mission-keyed strings deliberately keep the target, restriction, and exit condition.
# Do not replace these with generic mission-number labels.
$missionText = @{
    de = @{
        '01_01_a_long_shadow' = @{ Title='Ein langer Schatten'; Objective='K-525 verfolgen und klassifizieren, dann abdrehen.'; Description='K-525 östlich von Hokkaido verfolgen, klassifizieren und abdrehen.' }
        '02_02_war_warning' = @{ Title='Kriegswarnung'; Objective='Das Victor-III-U-Boot versenken und abdrehen.'; Description='Das Victor-III-U-Boot im Oyashio-Gebiet vernichten und abdrehen.' }
        '03_03_ryukyu_screen' = @{ Title='Ryukyu-Sperre'; Objective='Den sowjetischen ASW-Schirm durchbrechen und abdrehen.'; Description='Den sowjetischen ASW-Schirm südlich der Ryukyu-Inseln durchbrechen.' }
        '04_04_laperouse_gate' = @{ Title='La-Pérouse-Tor'; Objective='Die Meerenge passieren und nach Norden abdrehen.'; Description='Die La-Pérouse-Straße passieren, bevor die Suche schließt.' }
        '05_05_carrier_killer' = @{ Title='Trägerjäger'; Objective='Das Kommando des Trägerschirms vernichten und abdrehen.'; Description='Das Kommando des sowjetischen Trägerschirms vernichten.' }
        '06_06_through_kurils' = @{ Title='Durch die Kurilen'; Objective='Die Bussol-Straße durchdringen und nach Norden abdrehen.'; Description='Die ASW-Sperre der Bussol-Straße durchdringen.' }
        '07_07_bastion_watch' = @{ Title='Bastionswache'; Objective='K-433 ohne Feuereröffnung klassifizieren und abdrehen.'; Description='K-433 aufklären; ein Angriff ist verboten.' }
        '08_08_hammer_petropavlovsk' = @{ Title='Hammer bei Petropawlowsk'; Objective='Die ASW-Führungs- und Versorgungsgruppe vor Petropawlowsk ausschalten und abdrehen.'; Description='Die vor Petropawlowsk liegende ASW-Führungs- und Versorgungsgruppe überfallen.' }
        '09_09_last_deterrent' = @{ Title='Letzte Abschreckung'; Objective='K-433 vernichten und aus der Bastion abdrehen.'; Description='K-433 in der Bastion vernichten und anschließend abdrehen.' }
        'O1_O1_cold_wake' = @{ Title='Kalte Spur'; Objective='Die AGI ohne Feuereröffnung klassifizieren und abdrehen.'; Description='Die sowjetische AGI unbemerkt verfolgen und klassifizieren.' }
        'O2_O2_picket_line' = @{ Title='Die Vorpostenlinie'; Objective='K-525s ASW-Vorposten kartieren und abdrehen.'; Description='Die ASW-Vorposten um K-525 kartieren.' }
        'O3_O3_tenders_wake' = @{ Title='Im Kielwasser des Tenders'; Objective='Magadansky Komsomolets verfolgen und abdrehen.'; Description='Den Tender Magadansky Komsomolets verfolgen.' }
    }
    es = @{
        '01_01_a_long_shadow' = @{ Title='Una larga sombra'; Objective='Siga y clasifique K-525; después retírese.'; Description='Siga y clasifique K-525 al este de Hokkaido.' }
        '02_02_war_warning' = @{ Title='Alerta de guerra'; Objective='Destruya al Victor III y retírese.'; Description='Destruya al submarino Victor III en el Oyashio.' }
        '03_03_ryukyu_screen' = @{ Title='Pantalla Ryukyu'; Objective='Rompa la pantalla ASW soviética y retírese.'; Description='Rompa la pantalla ASW soviética al sur de las Ryukyu.' }
        '04_04_laperouse_gate' = @{ Title='Paso de La Pérouse'; Objective='Cruce el estrecho y retírese al norte.'; Description='Cruce el estrecho de La Pérouse antes de que cierre la búsqueda.' }
        '05_05_carrier_killer' = @{ Title='Cazador de portaaviones'; Objective='Destruya el mando de la pantalla del portaaviones y retírese.'; Description='Destruya el mando de la pantalla soviética del portaaviones.' }
        '06_06_through_kurils' = @{ Title='A través de las Kuriles'; Objective='Penetre el estrecho de Bussol y retírese al norte.'; Description='Penetre la barrera ASW del estrecho de Bussol.' }
        '07_07_bastion_watch' = @{ Title='Vigilia del bastión'; Objective='Clasifique K-433 sin abrir fuego y retírese.'; Description='Reconozca K-433; está prohibido atacarlo.' }
        '08_08_hammer_petropavlovsk' = @{ Title='Martillo en Petropávlovsk'; Objective='Embosque al grupo ASW de mando y abastecimiento frente a Petropávlovsk y retírese.'; Description='Embosque al grupo ASW de mando y abastecimiento en el mar.' }
        '09_09_last_deterrent' = @{ Title='La última disuasión'; Objective='Destruya K-433 y retírese del bastión.'; Description='Destruya K-433 dentro del bastión y después retírese.' }
        'O1_O1_cold_wake' = @{ Title='Estela fría'; Objective='Clasifique al AGI sin abrir fuego y retírese.'; Description='Siga y clasifique discretamente al AGI soviético.' }
        'O2_O2_picket_line' = @{ Title='La línea de piquetes'; Objective='Trace los piquetes ASW de K-525 y retírese.'; Description='Cartografíe los piquetes ASW que protegen K-525.' }
        'O3_O3_tenders_wake' = @{ Title='La estela del tender'; Objective='Siga al Magadansky Komsomolets y retírese.'; Description='Siga al tender Magadansky Komsomolets.' }
    }
    fr = @{
        '01_01_a_long_shadow' = @{ Title='Une longue ombre'; Objective='Suivez et identifiez K-525, puis repliez-vous.'; Description="Suivez K-525 à l’est d’Hokkaido et identifiez-le." }
        '02_02_war_warning' = @{ Title='Alerte de guerre'; Objective='Détruisez le Victor III puis repliez-vous.'; Description="Détruisez le sous-marin Victor III dans l'Oyashio." }
        '03_03_ryukyu_screen' = @{ Title='Écran Ryukyu'; Objective="Percez l'écran ASM soviétique puis repliez-vous."; Description="Percez l'écran ASM soviétique au sud des Ryukyu." }
        '04_04_laperouse_gate' = @{ Title='Porte de La Pérouse'; Objective='Franchissez le détroit et repliez-vous vers le nord.'; Description='Franchissez le détroit de La Pérouse avant la fermeture de la recherche.' }
        '05_05_carrier_killer' = @{ Title='Chasseur de porte-avions'; Objective="Détruisez le commandement de l'écran du porte-avions puis repliez-vous."; Description="Détruisez le commandement de l'écran soviétique du porte-avions." }
        '06_06_through_kurils' = @{ Title='À travers les Kouriles'; Objective='Pénétrez le détroit de Bussol et repliez-vous vers le nord.'; Description='Pénétrez la barrière ASM du détroit de Bussol.' }
        '07_07_bastion_watch' = @{ Title='Veille du bastion'; Objective='Identifiez K-433 sans tirer puis repliez-vous.'; Description='Reconnaissez K-433; toute attaque est interdite.' }
        '08_08_hammer_petropavlovsk' = @{ Title='Marteau à Petropavlovsk'; Objective='Tendez une embuscade au groupe ASM de commandement et de ravitaillement puis repliez-vous.'; Description='Frappez le groupe ASM au large de Petropavlovsk.' }
        '09_09_last_deterrent' = @{ Title='La dernière dissuasion'; Objective='Détruisez K-433 et quittez le bastion.'; Description='Détruisez K-433 dans le bastion puis repliez-vous.' }
        'O1_O1_cold_wake' = @{ Title='Sillage froid'; Objective="Identifiez l'AGI sans tirer puis repliez-vous."; Description="Suivez discrètement l'AGI soviétique." }
        'O2_O2_picket_line' = @{ Title='La ligne de piquets'; Objective='Cartographiez les piquets ASM de K-525 puis repliez-vous.'; Description='Cartographiez les piquets ASM protégeant K-525.' }
        'O3_O3_tenders_wake' = @{ Title='Le sillage du tender'; Objective='Suivez Magadansky Komsomolets puis repliez-vous.'; Description='Suivez le tender Magadansky Komsomolets.' }
    }
    ru = @{
        '01_01_a_long_shadow' = @{ Title='Длинная тень'; Objective='Проследить и опознать К-525, затем отойти.'; Description='Проследить за К-525 к востоку от Хоккайдо и опознать её.' }
        '02_02_war_warning' = @{ Title='Предупреждение о войне'; Objective='Уничтожить «Виктор-III» и отойти.'; Description='Уничтожить подводную лодку «Виктор-III» в Оясио.' }
        '03_03_ryukyu_screen' = @{ Title='Рюкюский заслон'; Objective='Прорвать советский противолодочный заслон и отойти.'; Description='Прорвать советский противолодочный заслон южнее Рюкю.' }
        '04_04_laperouse_gate' = @{ Title='Ворота Лаперуза'; Objective='Пройти пролив и отойти на север.'; Description='Пройти пролив Лаперуза до замыкания поиска.' }
        '05_05_carrier_killer' = @{ Title='Охотник на авианосцы'; Objective='Уничтожить командование экраном авианосца и отойти.'; Description='Уничтожить командный корабль советского авианосного экрана.' }
        '06_06_through_kurils' = @{ Title='Через Курилы'; Objective='Прорвать пролив Буссоль и отойти на север.'; Description='Прорвать противолодочный барьер пролива Буссоль.' }
        '07_07_bastion_watch' = @{ Title='Наблюдение за бастионом'; Objective='Опознать К-433, не открывая огонь, и отойти.'; Description='Разведать К-433; атаковать запрещено.' }
        '08_08_hammer_petropavlovsk' = @{ Title='Молот у Петропавловска'; Objective='Устроить засаду на группу ПЛО управления и снабжения, затем отойти.'; Description='Атаковать морскую группу ПЛО у Петропавловска.' }
        '09_09_last_deterrent' = @{ Title='Последнее сдерживание'; Objective='Уничтожить К-433 и выйти из бастиона.'; Description='Уничтожить К-433 в бастионе и отойти.' }
        'O1_O1_cold_wake' = @{ Title='Холодный след'; Objective='Опознать АГИ, не открывая огонь, и отойти.'; Description='Скрытно сопровождать советское АГИ.' }
        'O2_O2_picket_line' = @{ Title='Линия дозора'; Objective='Нанести на карту противолодочные дозоры К-525 и отойти.'; Description='Нанести на карту дозоры ПЛО вокруг К-525.' }
        'O3_O3_tenders_wake' = @{ Title='В кильватере тендера'; Objective='Сопровождать Magadansky Komsomolets и отойти.'; Description='Сопровождать тендер Magadansky Komsomolets.' }
    }
    cn = @{
        '01_01_a_long_shadow'=@{Title='漫长暗影';Objective='跟踪并识别K-525，然后撤离。';Description='在北海道以东跟踪并识别K-525。'}
        '02_02_war_warning'=@{Title='战争警报';Objective='击沉维克托III后撤离。';Description='在亲潮海域击沉维克托III潜艇。'}
        '03_03_ryukyu_screen'=@{Title='琉球屏障';Objective='突破苏军反潜屏障后撤离。';Description='突破琉球以南的苏军反潜屏障。'}
        '04_04_laperouse_gate'=@{Title='拉彼鲁兹之门';Objective='穿越海峡并向北撤离。';Description='在搜索合拢前穿越拉彼鲁兹海峡。'}
        '05_05_carrier_killer'=@{Title='航母猎手';Objective='摧毁航母警戒指挥舰后撤离。';Description='摧毁苏军航母警戒屏的指挥舰。'}
        '06_06_through_kurils'=@{Title='穿越千岛';Objective='突破布索尔海峡并向北撤离。';Description='突破布索尔海峡的反潜屏障。'}
        '07_07_bastion_watch'=@{Title='堡垒监视';Objective='不得开火识别K-433后撤离。';Description='侦察K-433；禁止攻击。'}
        '08_08_hammer_petropavlovsk'=@{Title='彼得罗巴甫洛夫斯克之锤';Objective='伏击反潜指挥补给群后撤离。';Description='在彼得罗巴甫洛夫斯克外海伏击反潜群。'}
        '09_09_last_deterrent'=@{Title='最后威慑';Objective='摧毁K-433并离开堡垒。';Description='在堡垒内摧毁K-433后撤离。'}
        'O1_O1_cold_wake'=@{Title='冷迹';Objective='不得开火识别AGI后撤离。';Description='隐蔽跟踪苏军AGI。'}
        'O2_O2_picket_line'=@{Title='警戒线';Objective='绘制K-525反潜哨戒后撤离。';Description='绘制保护K-525的反潜哨舰。'}
        'O3_O3_tenders_wake'=@{Title='补给舰尾迹';Objective='跟踪Magadansky Komsomolets后撤离。';Description='跟踪补给舰Magadansky Komsomolets。'}
    }
    ja = @{
        '01_01_a_long_shadow'=@{Title='長い影';Objective='K-525を追尾・識別して離脱。';Description='北海道東方でK-525を追尾し識別する。'}; '02_02_war_warning'=@{Title='戦争警報';Objective='ヴィクターIIIを撃沈して離脱。';Description='親潮海域でヴィクターIIIを撃沈する。'}; '03_03_ryukyu_screen'=@{Title='琉球スクリーン';Objective='ソ連ASWスクリーンを突破して離脱。';Description='琉球南方のソ連ASWスクリーンを突破する。'}; '04_04_laperouse_gate'=@{Title='ラ・ペルーズ門';Objective='海峡を通過し北へ離脱。';Description='捜索が閉じる前に海峡を通過する。'}; '05_05_carrier_killer'=@{Title='空母キラー';Objective='空母スクリーン司令部を破壊して離脱。';Description='ソ連空母スクリーンの司令部を破壊する。'}; '06_06_through_kurils'=@{Title='千島越え';Objective='ブッソル海峡を突破し北へ離脱。';Description='ブッソル海峡のASW障壁を突破する。'}; '07_07_bastion_watch'=@{Title='バスチオン監視';Objective='発砲せずK-433を識別して離脱。';Description='K-433を偵察する。攻撃禁止。'}; '08_08_hammer_petropavlovsk'=@{Title='ペトロパブロフスクの槌';Objective='ASW指揮・補給群を待ち伏せて離脱。';Description='沖合のASW指揮補給群を奇襲する。'}; '09_09_last_deterrent'=@{Title='最後の抑止';Objective='K-433を破壊しバスチオンから離脱。';Description='バスチオン内のK-433を破壊する。'}; 'O1_O1_cold_wake'=@{Title='冷たい航跡';Objective='発砲せずAGIを識別して離脱。';Description='ソ連AGIを秘匿追尾する。'}; 'O2_O2_picket_line'=@{Title='哨戒線';Objective='K-525のASW哨戒を地図化して離脱。';Description='K-525を守るASW哨戒を地図化する。'}; 'O3_O3_tenders_wake'=@{Title='補給艦の航跡';Objective='Magadansky Komsomoletsを追尾して離脱。';Description='補給艦Magadansky Komsomoletsを追尾する。'}
    }
    ko = @{
        '01_01_a_long_shadow'=@{Title='긴 그림자';Objective='K-525를 추적·식별한 뒤 철수.';Description='홋카이도 동쪽에서 K-525를 추적한다.'}; '02_02_war_warning'=@{Title='전쟁 경보';Objective='빅터 III를 격침하고 철수.';Description='오야시오에서 빅터 III를 격침한다.'}; '03_03_ryukyu_screen'=@{Title='류큐 장벽';Objective='소련 ASW 장벽을 돌파하고 철수.';Description='류큐 남쪽 ASW 장벽을 돌파한다.'}; '04_04_laperouse_gate'=@{Title='라페루즈 관문';Objective='해협을 통과해 북쪽으로 철수.';Description='수색이 닫히기 전 해협을 통과한다.'}; '05_05_carrier_killer'=@{Title='항모 사냥꾼';Objective='항모 경계 지휘함을 파괴하고 철수.';Description='소련 항모 경계 지휘함을 파괴한다.'}; '06_06_through_kurils'=@{Title='쿠릴 돌파';Objective='부솔 해협을 돌파해 북쪽으로 철수.';Description='부솔 해협 ASW 장벽을 돌파한다.'}; '07_07_bastion_watch'=@{Title='요새 감시';Objective='발포 없이 K-433을 식별하고 철수.';Description='K-433을 정찰한다. 공격 금지.'}; '08_08_hammer_petropavlovsk'=@{Title='페트로파블롭스크의 망치';Objective='ASW 지휘·보급단을 매복하고 철수.';Description='근해 ASW 지휘 보급단을 기습한다.'}; '09_09_last_deterrent'=@{Title='최후의 억제';Objective='K-433을 파괴하고 요새를 이탈.';Description='요새 안의 K-433을 파괴한다.'}; 'O1_O1_cold_wake'=@{Title='차가운 항적';Objective='발포 없이 AGI를 식별하고 철수.';Description='소련 AGI를 은밀히 추적한다.'}; 'O2_O2_picket_line'=@{Title='초계선';Objective='K-525의 ASW 초계를 지도화하고 철수.';Description='K-525 주변 ASW 초계를 지도화한다.'}; 'O3_O3_tenders_wake'=@{Title='보급함 항적';Objective='Magadansky Komsomolets를 추적하고 철수.';Description='보급함 Magadansky Komsomolets를 추적한다.'}
    }
    vn = @{
        '01_01_a_long_shadow'=@{Title='Bóng dài';Objective='Theo dõi, nhận dạng K-525 rồi rút lui.';Description='Theo dõi K-525 ở phía đông Hokkaido.'}; '02_02_war_warning'=@{Title='Cảnh báo chiến tranh';Objective='Đánh chìm Victor III rồi rút lui.';Description='Đánh chìm Victor III tại Oyashio.'}; '03_03_ryukyu_screen'=@{Title='Màn chắn Ryukyu';Objective='Phá màn ASW Liên Xô rồi rút lui.';Description='Phá màn ASW phía nam Ryukyu.'}; '04_04_laperouse_gate'=@{Title='Cửa La Pérouse';Objective='Qua eo biển rồi rút về phía bắc.';Description='Qua eo biển trước khi cuộc tìm kiếm khép lại.'}; '05_05_carrier_killer'=@{Title='Thợ săn tàu sân bay';Objective='Phá hủy chỉ huy màn tàu sân bay rồi rút lui.';Description='Phá hủy chỉ huy màn tàu sân bay Liên Xô.'}; '06_06_through_kurils'=@{Title='Qua Kuril';Objective='Vượt eo Bussol rồi rút về bắc.';Description='Vượt hàng rào ASW eo Bussol.'}; '07_07_bastion_watch'=@{Title='Theo dõi pháo đài';Objective='Nhận dạng K-433 không nổ súng rồi rút lui.';Description='Trinh sát K-433; cấm tấn công.'}; '08_08_hammer_petropavlovsk'=@{Title='Búa tại Petropavlovsk';Objective='Phục kích nhóm ASW chỉ huy tiếp tế rồi rút lui.';Description='Phục kích nhóm ASW ngoài khơi Petropavlovsk.'}; '09_09_last_deterrent'=@{Title='Răn đe cuối cùng';Objective='Phá hủy K-433 rồi rời pháo đài.';Description='Phá hủy K-433 trong pháo đài.'}; 'O1_O1_cold_wake'=@{Title='Vệt lạnh';Objective='Nhận dạng AGI không nổ súng rồi rút lui.';Description='Theo dõi kín AGI Liên Xô.'}; 'O2_O2_picket_line'=@{Title='Tuyến gác';Objective='Lập bản đồ ASW của K-525 rồi rút lui.';Description='Lập bản đồ các chốt ASW quanh K-525.'}; 'O3_O3_tenders_wake'=@{Title='Vệt của tàu tiếp tế';Objective='Theo dõi Magadansky Komsomolets rồi rút lui.';Description='Theo dõi tàu tiếp tế Magadansky Komsomolets.'}
    }
}

foreach ($mission in $missions) {
    $iniPath = Join-Path $CampaignRoot ('missions\' + $mission.File + '.ini')
    $briefDir = Join-Path $CampaignRoot ('missions\' + $mission.File + '_briefing')
    New-Item -ItemType Directory -Force -Path $briefDir | Out-Null
    foreach ($locale in $locales.Keys) {
        $labels = $locales[$locale]
        $localized = if ($missionText.ContainsKey($locale)) { $missionText[$locale][$mission.File] } else { $null }
        $title = if ($locale -eq 'en') { $mission.Title } elseif ($null -ne $localized) { $localized.Title } else { $labels.Prefix + $mission.Code + $labels.Suffix }
        $objective = if ($locale -eq 'en') { $mission.Objective } elseif ($null -ne $localized) { $localized.Objective } else { $labels.ObjectiveText }
        $body = "{0}`n{1}`n`n{2}`n{3}`n`n{4}`n{5}`n`n{6}`n{7}" -f $labels.Header, $title, $labels.Situation, $labels.SituationText, $labels.Mission, $objective, $labels.Friendly, $labels.Close
        $escaped = [System.Security.SecurityElement]::Escape($body)
        $xml = '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"><Viewbox Stretch="Uniform"><Border Width="1200" Height="760" Background="#101922" Padding="44"><StackPanel TextElement.Foreground="#D8DCE0" TextElement.FontFamily="Roboto"><TextBlock TextWrapping="Wrap" FontSize="18" LineHeight="28">' + $escaped + '</TextBlock></StackPanel></Border></Viewbox></Grid>'
        Set-Content -LiteralPath (Join-Path $briefDir ('BriefingText_' + $locale + '.xml')) -Value $xml -Encoding utf8NoBOM
    }
    $section = ''
    $rewritten = foreach ($line in Get-Content -LiteralPath $iniPath) {
        if ($line -match '^\[Language_(.+)\]$') { $section = $Matches[1] }
        if ($line -match '^MissionBriefingLeftPane=') { 'MissionBriefingLeftPane=campaigns/pacific-depths-85/missions/' + $mission.File + '_briefing/BriefingText_' + $section + '.xml' }
        elseif ($section -ne 'en' -and $line -match '^Name=') { if ($null -ne $missionText[$section][$mission.File]) { 'Name=' + $missionText[$section][$mission.File].Title } else { 'Name=' + $locales[$section].Prefix + $mission.Code + $locales[$section].Suffix } }
        elseif ($section -ne 'en' -and $line -match '^Description=') { if ($null -ne $missionText[$section][$mission.File]) { 'Description=' + $missionText[$section][$mission.File].Description } else { 'Description=' + $locales[$section].DescriptionText } }
        else { $line }
    }
    Set-Content -LiteralPath $iniPath -Value $rewritten -Encoding utf8NoBOM
}
