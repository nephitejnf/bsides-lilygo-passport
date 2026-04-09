# Facilitator Guide — BSides BadUSB Lab

**Do not distribute this file to participants.**

## Overview

The firmware has 3 bugs in the HID keycode mapping table (`main/hid_keyboard.c`,
`s_ascii_keymap[]`). The payload `cat ~/flag.txt` types garbled text.
Participants must find and fix the bugs, then explain what they learned.

**The fix is intentionally approachable.** The real assessment is whether they can
explain *why* it was broken — not just *that* it was broken.

---

## What's broken

The payload types: **`cAy ~/flAg/yxy`** instead of `cat ~/flag.txt`

| Bug | Line | What's wrong | Correct value | What types |
|-----|------|-------------|---------------|------------|
| 1 | `.` entry (0x2E) | `HID_KEY_SLASH` | `HID_KEY_PERIOD` | `/` instead of `.` |
| 2 | `/` entry (0x2F) | `HID_KEY_PERIOD` | `HID_KEY_SLASH` | `.` instead of `/` |
| 3 | `a` entry (0x61) | `_S` (Shift) modifier | `_N` (no modifier) | `A` instead of `a` |
| 4 | `t` entry (0x74) | `HID_KEY_Y` | `HID_KEY_T` | `y` instead of `t` |

### Fix (diff)

```c
// Line ~145: swap these two keycodes back
- /* 0x2E '.'  */ { _N, HID_KEY_SLASH },
- /* 0x2F '/'  */ { _N, HID_KEY_PERIOD },
+ /* 0x2E '.'  */ { _N, HID_KEY_PERIOD },
+ /* 0x2F '/'  */ { _N, HID_KEY_SLASH },

// Line ~181: change _S back to _N for lowercase 'a'
- { _S, HID_KEY_A }, { _N, HID_KEY_B }, ...
+ { _N, HID_KEY_A }, { _N, HID_KEY_B }, ...

// Line ~187: change HID_KEY_Y back to HID_KEY_T for lowercase 't'
- { _N, HID_KEY_S }, { _N, HID_KEY_Y }, { _N, HID_KEY_U },
+ { _N, HID_KEY_S }, { _N, HID_KEY_T }, { _N, HID_KEY_U },
```

---

## Progressive hints (give verbally if stuck)

### Hint 1 — Observation (give after ~2 min if no progress)
> "Plug it in and press BOOT. Compare what it types to what it should type.
> Which specific characters came out wrong?"

### Hint 2 — Location (give if they don't know where to look)
> "The payload string is fine — the problem is how characters get converted
> to keystrokes. Look at `hid_keyboard.c`."

### Hint 3 — Mechanism (give if they found the file but are confused)
> "USB keyboards don't send letters. They send numeric scancodes, and the
> host OS decides what character that means. There's a mapping table in
> the code — find it."

### Hint 4 — Specific (give as a last resort)
> "Look at the `s_ascii_keymap` array. Each entry has a modifier and a keycode.
> Find the entries for the characters that typed wrong and compare them to
> nearby correct entries."

---

## Explanation questions (the actual assessment)

After they fix it, ask these. The goal is understanding, not just code editing.

### Phase 2 — Investigation (must answer to "pass")

1. **"What did you fix and why did it cause wrong characters?"**
   - Good answer: The table maps ASCII characters to HID scancodes. The keycodes
     were swapped/wrong, so the host OS interpreted different physical keys than
     intended.
   - Great answer: Mentions that HID keyboards send Usage IDs (scancodes), not
     characters. The host OS maps scancodes to characters using its keyboard
     layout. The device has no idea what the host will display.

2. **"What device class is this? Why did the OS trust it immediately?"**
   - Answer: USB HID (Human Interface Device). Operating systems auto-load HID
     drivers because keyboards and mice are essential to use the computer. There's
     no "install driver?" prompt — it just works.

3. **"If the target machine was using a French (AZERTY) keyboard layout, would
   this attack still work? Why or why not?"**
   - Answer: No. The same scancodes would produce different characters because
     the French layout maps them differently. For example, HID_KEY_A would
     produce 'q' on AZERTY. Real BadUSB tools (like Rubber Ducky) need
     locale-specific keymap files for this reason.

### Phase 3 — Defense (discussion, no single right answer)

4. **"What would stop this in an enterprise?"**
   - USB device whitelisting (by VID/PID or device class)
   - USBGuard (Linux), Group Policy (Windows) to block new HID devices
   - Physical USB port blocking / epoxy
   - User awareness training

5. **"Would EDR catch this?"**
   - Maybe. EDR might flag rapid keystroke injection, or the spawned terminal
     process. But the keystrokes themselves look identical to a real keyboard —
     there's no malware binary to scan. This is why BadUSB is effective: the
     attack IS legitimate HID traffic.

6. **"The device shows up as 'Trust Demo Keyboard' in lsusb. Could an attacker
   change that? Would it help them?"**
   - Yes, USB string descriptors are trivially configurable in firmware. An
     attacker would set VID/PID and product strings to match a known keyboard
     (e.g., Logitech, Dell). This is social engineering at the hardware level.

---

## Timing guide

| Phase | Target | Activity |
|-------|--------|----------|
| Setup | 1 min | Hand out device, open the project in their editor |
| Puzzle | 2-5 min | Find and fix the keymap bugs, rebuild and flash |
| Investigation | 5-8 min | Questions 1-3, discussion |
| Defense | 5-8 min | Questions 4-6, group discussion |
| **Total** | **~15-20 min** | |

---

## Rebuild & flash (for reference)

```bash
idf.py build
idf.py -p /dev/ttyACM0 flash    # adjust port as needed
```

Participants should rebuild after fixing the code and verify the payload
types correctly: `cat ~/flag.txt`
