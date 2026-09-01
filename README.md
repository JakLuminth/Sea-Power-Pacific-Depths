# Pacific Depths '85

Pacific Depths '85 is an original persistent, authored-linear submarine campaign for Sea Power 0.8.2. It follows a U.S. Navy Los Angeles-class boat from the first shadowing patrol off Hokkaido through the final deterrent patrol inside the Soviet bastion in the Sea of Okhotsk.

The campaign contains nine main missions, three optional intelligence operations, and seven narrative timeline events. Direct control is limited to submarines. USS Los Angeles is the persistent flagship; USS Drum is assigned after mission 3 and USS San Francisco after mission 6. Companion losses persist without blocking the story, while losing the flagship fails the active mission.

## Installation

The deployable campaign is the `mod\campaigns\pacific-depths-85` folder. Copy that folder directly into Sea Power's `StreamingAssets` directory so the installed layout is:

`<Sea Power installation>\Sea Power_Data\StreamingAssets\pacific-depths-85`

For Steam Workshop publication, upload the `pacific-depths-85` campaign folder rather than the repository root. The repository deliberately keeps campaign content beneath `mod\campaigns` so documentation, validation tools, Git metadata, and other development artifacts are not included in the Workshop item.

Contributors may optionally point the installed `StreamingAssets\pacific-depths-85` entry at `mod\campaigns\pacific-depths-85` with a Windows directory symbolic link. This is a development convenience, not the normal installation method. No installation or removal scripts are included.

## Design and persistence

The campaign uses one authored Moderate-style baseline, with missions targeting approximately 60–90 minutes. There is no points economy, purchase screen, roster builder, commander setup, or custom Task Force difficulty picker. Patrol groups are fixed by the story: Los Angeles alone for missions 1–3 and optional 1, Los Angeles with Drum for missions 4–6 and optional 2, and all three boats for missions 7–9 and optional 3. Rearm and repair occur at the starts of missions 4, 6, and 8; there is no replenishment between missions 8 and 9.

Dynamic Unit Generation is used with constrained historical pools, authored ASW formations, mission-specific spawn zones, and persistent named enemy contacts. Objective-critical boats and tenders use exact one-for-one slots. Neutral traffic is authored and fixed.

The campaign variables are:

- `PD85_O1_AGITracked`
- `PD85_O2_PicketsMapped`
- `PD85_O3_TenderTracked`
- `PD85_M8_ASWSuppressed`

Optional operations alter intelligence, reveals, and ASW pressure but never gate main-mission progression.

## Validation

Run the static validator from the repository root:

```powershell
.\tools\validate_campaign.ps1 -GameRoot 'C:\Program Files (x86)\Steam\steamapps\common\Sea Power'
```

The validator checks campaign graph structure, language parity, XML assets, mission references, static submarine patrol slots and CampaignTag continuity, approved replenishment timing, variables, dynamic roster IDs, and installed unit identifiers. Runtime acceptance additionally requires launching and completing all twelve operations on the Moderate baseline and reviewing `Player.log` and `ScriptEngine.log`.

## Source conventions and acknowledgements

The structure and dynamic-generation conventions were cross-checked against the supplied Workshop guides:

- [Task Force Mode guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3756769210)
- [Trigger and Condition guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3756786658)
- [Dynamic Unit Generation guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3778809391)

Adopted conventions include authored static submarine slots with stable `CampaignTag` values, constrained theater rosters, persistent named contacts, formation stations, spawn zones, dynamic-generation anchors, and uppercase trigger logic. Narrative text and campaign art are original and not copied from those references.

This project does not publish automatically to Workshop and intentionally produces no ZIP archive.
