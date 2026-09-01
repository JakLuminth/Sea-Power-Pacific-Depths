# Pacific Depths '85

Pacific Depths '85 is an original submarine Task Force Mode campaign for Sea Power 0.8.2. It follows a U.S. Navy Los Angeles-class boat from the first shadowing patrol off Hokkaido through the final deterrent patrol inside the Soviet bastion in the Sea of Okhotsk.

The campaign contains nine main missions, three optional intelligence operations, and seven narrative timeline events. The player roster contains submarines only. USS Los Angeles is the persistent flagship; USS Drum becomes available after mission 3 and USS San Francisco after mission 6. Companion losses persist without blocking the story, while losing the flagship fails the active mission.

## Installation

The deployable content is the `mod` directory. During development it is intended to be exposed to the game as a Windows directory symbolic link:

`<Sea Power installation>\Sea Power_Data\StreamingAssets\pacific-depths-85` → `<repository>\mod`

No installation or removal scripts are included. A directory soft link is required; hard links do not apply to directories. The link is created and verified directly during development with elevation because the Steam directory is protected.

## Design and persistence

The campaign targets Moderate difficulty missions of approximately 60–90 minutes. Easy, Moderate, and Difficult presets adjust formation pressure and logistics rather than unit hit points. Rearm and repair are available after missions 3, 5, and 7; there is no replenishment between missions 8 and 9.

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

The validator checks campaign graph structure, language parity, XML assets, mission references, submarine-only player slots, variables, dynamic roster IDs, and installed unit identifiers. Runtime acceptance additionally requires launching and completing all twelve operations on Moderate and reviewing `Player.log` and `ScriptEngine.log`.

## Source conventions and acknowledgements

The structure and dynamic-generation conventions were cross-checked against the supplied Workshop guides:

- [Task Force Mode guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3756769210)
- [Trigger and Condition guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3756786658)
- [Dynamic Unit Generation guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3778809391)

Adopted conventions include the `Taskforce1Vessel1`/`TaskForceModeAnchor` generated-mission convention where applicable, authored detached submarine slots, constrained theater rosters, persistent named contacts, formation stations, spawn zones, and uppercase trigger logic. Narrative text and campaign art are original and not copied from those references.

This project does not publish automatically to Workshop and intentionally produces no ZIP archive.
