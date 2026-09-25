# Agent Instructions

## Project goal

Maintain a small macOS e-ink display shell around the official WeRead website. The application improves local rendering without becoming a third-party content client.

## Required boundaries

- Load reading content only from the official `weread.qq.com` website.
- Do not capture, log, export, upload, or otherwise expose cookies, tokens, account data, or book content.
- Do not add private API calls, traffic interception, content decryption, automated reading-time reporting, or bulk downloading.
- Keep external top-level links outside the embedded WebKit view unless they are under `weread.qq.com`.
- Preserve existing user settings when changing preference keys; add migrations when required.

## Implementation rules

- Prefer the smallest change that solves the verified problem.
- Keep e-ink style rules centralized in `EInkStyle.swift`.
- Before changing WeRead CSS selectors, inspect the current official reader page and verify both vertical scrolling and horizontal pagination modes.
- Vertical-mode width rules must not affect `.wr_horizontalReader`.
- Keep controls usable without precise pointer dragging; prefer explicit minus and plus buttons for e-ink displays.
- Do not commit `.build/`, `dist/`, local WebKit data, screenshots, credentials, or generated application bundles.

## Verification

Run these checks after every functional change:

```bash
swift test
./scripts/build-app.sh
codesign --verify --deep --strict --verbose=2 dist/WeReadMacElink.app
```

For display changes, also launch the newly built application and verify the behavior on an actual external e-ink display. Report unit-test, build, signature, and runtime verification separately.
