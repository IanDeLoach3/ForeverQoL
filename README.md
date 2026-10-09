# ForeverQoL

Quality-of-life automation for WoW Forever. 26 small features, every one of them individually toggleable and off by default unless it's genuinely low-risk — no combat automation, no forbidden-data tricks, nothing that runs into Forever's addon restrictions. Just the repetitive clicking that a quality-of-life addon should be handling for you.

Type `/fqol` in game to open the settings panel, or click the minimap button.

## Why this addon

Forever runs the modern/retail API, not the Classic one — so most existing Classic-era QoL addons don't load without real changes, and the couple of retail options that do work have had reported conflicts on Forever. ForeverQoL was built and tested against Forever's actual API from the ground up (`C_Item`, `C_Container`, `C_PartyInfo`, `C_GossipInfo`, and friends), with Classic Era compatibility kept alongside it wherever the two clients diverge.

## Features

Vendor
- Auto-repair at vendors (on by default)
- Prefer guild bank funds for repairs, falling back to your own gold
- Auto-sell every grey (Poor-quality) item — never touches anything above grey

Mail
- "Take All" button on the inbox — collects gold and attachments from every message, always skips cash-on-delivery mail so it can never charge you
- Auto-collect gold-only messages the instant you open the mailbox

Quests
- Auto-accept quests
- Auto-turn-in completed quests — but *only* when there's no reward choice to make. Anything with a choice always waits for you, so it can never pick wrong on your behalf
- Skip single-option NPC dialogue (off by default — it can skip flavor text worth reading)
- Hold Shift on any NPC to suppress all quest automation for that interaction

Social
- Auto-invite players who whisper a chosen keyword — set your own word, useful when you're recruiting or advertising in chat while questing
- Auto-decline duel requests
- Auto-accept group invites, but only from guildmates or friends — strangers still prompt you normally

Looting
- Faster auto-loot (respects your own auto-loot setting and modifier key)
- Skip the "this will bind to you" confirmation
- Skip disenchant-roll confirmations

Death & Travel *(all off by default — these are situational)*
- Auto-release on death
- Auto-accept resurrections
- Auto-accept summons

Interface
- Raise the maximum camera zoom-out distance
- Screenshot automatically on level up
- Minimap button (drag to reposition)
- Hide combat error spam ("Out of range," "Not enough mana," etc.) while keeping meaningful errors
- Durability warning at 20%
- Pre-fill the item-deletion confirmation text (off by default — this removes a deliberate safety step on purpose)

Chat
- `/fqol copy` — opens a selectable-text window of your recent chat, since WoW has no native way to copy chat out of the game
- Filter repeated spam in public channels only (never whispers, guild, party, or raid)

Tooltips
- Show item ID
- Show the vendor value of a whole stack, not just one item

## Design principles

- Nothing touches combat data. Forever hides enemy health, damage, and threat from addons entirely — this addon doesn't go near any of that, by design, not just by necessity.
- Nothing picks a reward for you. Auto-turn-in explicitly refuses to fire on any quest with a choice of rewards.
- Off by default whenever there's real judgment involved (auto-release, auto-summon, delete pre-fill). On by default only for things with essentially no downside (repair, sell junk, faster loot).
- Modular. Each feature lives in its own file and self-registers with the settings panel — nothing shared to break.

## Known limitations

- WoW Forever beta has a client-side bug where SavedVariables (all addon settings, for every addon) don't reliably persist across `/reload` or logout. This is not specific to ForeverQoL — it affects the whole addon ecosystem on Forever beta right now. Settings should save correctly and persist normally on Classic Era.
- Interface number: `11509` (Classic Era) and `16001` (WoW Forever), both confirmed directly against `GetBuildInfo()`.

## Feedback

Found something broken, or want a feature added? Type `/fqol bug` to report a bug or `/fqol suggest` to suggest a feature (or use the buttons at the bottom of the settings panel). It builds a ready-to-paste report with your game version, enabled features, and any recent ForeverQoL errors (no character info), plus a link to open an issue on GitHub: https://github.com/IanDeLoach3/ForeverQoL/issues. You can also leave a comment on the CurseForge project page.
