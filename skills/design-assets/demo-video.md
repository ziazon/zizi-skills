# Demo videos — record a scripted walkthrough of our own app

How to record a repeatable product demo by driving the real app with Playwright, for a landing
page, a store preview or docs. The video is recorded from the app, never generated.

Adapted from `video/references/product-demo-recording.md` in `coreyhaines31/marketingskills`
(MIT); rewritten.

## Contents

- When to script it
- Honesty rules for a demo
- Before recording
- Recording workflow
- Local-app gotchas
- Output formats
- Optional narration
- Before you hand it over

## When to script it

| Situation | Approach |
| --- | --- |
| A flow you'll re-record every release, or need pixel-identical between runs | **scripted recording** (this file) |
| A one-off walkthrough where a person's voice and pace matter | record the screen by hand |
| A native mobile app | the simulator's own recorder (e.g. `xcrun simctl io booted recordVideo`), with the same script-first steps |

## Honesty rules for a demo

- **The real app, doing what it does today.** No feature that hasn't shipped, no faked result,
  no speed-up that hides a slow step without saying so.
- **Demo data is invented but realistic.** Seed it from a script. Never record real customer
  data, even blurred.
- **No AI avatars or synthetic presenters passed off as real people**, and no cloned voice of a
  real person. A text-to-speech narrator is fine as a voice, not as a named person.
- **The browser bar may show the product's real public domain** in place of localhost. Never
  another company's domain.

The rest of marketing's [Honesty check](../marketing/SKILL.md) applies to captions as to any
page.

## Before recording

1. **Audience**: prospects, existing customers or developers. It sets caption tone and pace.
2. **Scene list**: one line per scene, written as the caption you want on screen (about 50–80
   characters each). This is the script.
3. **Start state**: logged in or not; a seeded demo user plus a programmatic login or cookies.
4. **Sound**: silent with captions by default. Add narration only when asked.
5. **Look**: app name, colors, logo, from design-guide and the project's brand record.

## Recording workflow

1. **Run the app locally** at a stable URL and click through the flow once in a real browser.
   A page that crashes on boot (often a missing env var) records as a blank video, silently.
2. **Seed and reset demo data** at the top of every run, touching only the rows the demo uses,
   so text selectors don't match leftovers from the last run.
3. **Script the flow as a Playwright test** ([tdd-skill](../tdd-skill/SKILL.md) covers how
   this project runs Playwright):
   - one fixed `viewport`, the same size as `recordVideo.size` (1280 × 800 is a sane default);
   - explicit waits (`waitForURL`, `getByRole(...).waitFor()`), never fixed sleeps;
   - actions slowed (`slowMo`, or a pause per step) so a viewer can follow;
   - a `step(label, caption, action)` helper that shows the caption, logs its time offset from
     the start, runs the action, and saves a screenshot named after the step if it fails.
4. **Make the cursor visible.** Playwright clicks without a pointer. Inject a fake cursor and a
   caption bar with `addInitScript`, and wrap clicks and fills in helpers that glide the cursor
   to the target, show a click ripple, then act. Keep targets above the caption bar.
5. **Optional title card and browser frame**: a still image held at the start (it doubles as the
   poster), and a tab-and-URL strip stacked on top of the recording with ffmpeg.
6. **Export** with ffmpeg: trim the blank first frames, encode H.264, and cut one file per target
   below. Keep the caption timings as a JSON file beside the video.

With narration, choose per step whether the caption plays **before** the action (a click that
navigates away; the default, so the voice never describes a page already gone), **during** it
(typing, opening a menu), or **after** it (describing the result).

## Local-app gotchas

| Symptom | Cause | Fix |
| --- | --- | --- |
| Every page bounces to login | `Secure` cookies are refused over plain HTTP on a non-localhost host | a recording-only env flag that drops `Secure` (and switches `SameSite=None` to `Lax`), or serve HTTPS with a self-signed cert and `ignoreHTTPSErrors: true` |
| Cursor and captions don't appear | the app's Content Security Policy blocks injected inline styles and scripts | `bypassCSP: true` on the recording browser context only; never loosen the app's CSP |
| The reset wiped the wrong database | the shell exported production DB variables and the seed command inherited them | pass an explicit env with the local DB to child processes; never forward `process.env`; use the array form of `spawnSync` |
| Selectors match two elements | rows left from an earlier run | reset at the top of the script, or sign up a fresh demo user each run |
| Cookie flags or env changes show up in the diff | recording-only config left behind | revert it before committing; the diff holds only the recorder script and seed data |

## Output formats

| Where it goes | Format |
| --- | --- |
| Landing page | short, muted, loopable MP4 (H.264) plus WebM, a poster image, lazy-loaded; check page weight against [web-performance.md](../frontend/web-performance.md) |
| App Store preview | 15–30 seconds, app footage only, at the device size Apple requires; see [platform-specs.md](../app-store/platform-specs.md) |
| Google Play preview | uploaded to YouTube (public or unlisted, no ads) and linked from the listing |
| Docs or changelog | a short MP4, or a GIF under a few MB |

Store previews autoplay muted, so the first seconds show the main job without sound. The
listing side is in [app-store](../app-store/SKILL.md).

## Optional narration

Use the captions as the script: one text-to-speech clip per caption (e.g. ElevenLabs, OpenAI's
TTS API), cached per step, with each step waiting for its clip's measured length. The API key
lives in an environment variable the script reads; never in chat, the repo or a committed
`.env`. If it isn't set, say which variable to set and record silent meanwhile.

## Before you hand it over

- [ ] The flow renders in a real browser, and the session survives every navigation.
- [ ] Demo data only; no real customer data anywhere in frame.
- [ ] Every shown feature is live today.
- [ ] Cursor visible on every click and fill; captions never cover the active element.
- [ ] The URL bar shows our public domain or localhost, nothing else.
- [ ] Recording-only config reverted.
- [ ] Each output matches its target's format and length.
