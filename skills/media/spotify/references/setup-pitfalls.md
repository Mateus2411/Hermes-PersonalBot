# Spotify Setup Pitfalls

## WSL: Browser doesn't open for OAuth

`hermes auth spotify` tries to open the Spotify authorization URL via `gio open`, which **fails silently in WSL** (no desktop environment). The terminal shows:

```
gio: https://accounts.spotify.com/authorize?...: Operation not supported
```

**Fix:** The URL is printed in the terminal output right above the `gio:` error line. Copy-paste it manually into the Windows browser. After the user authorizes, the redirect to `http://127.0.0.1:43827/spotify/callback` is captured by the Hermes local server running in WSL.

The full URL includes the `code_challenge`, `redirect_uri`, and `scope` params — it's safe to share; only the `state` param is a one-time CSRF token. The user must copy the *entire* line (it spans one line in the terminal).

## "Which API/SDK are you planning to use?" — can't find Web API

When creating an app on the Spotify Developer Dashboard (`https://developer.spotify.com/dashboard` → Create app), Spotify prompts:

> **Which API/SDK are you planning to use?**

This is a multi-select list. The Hermes OAuth flow needs the **Web API** option checked. SDK options (Web Playback SDK, iOS SDK, Android SDK) are irrelevant — they're for building audio players, not for REST API access.

If the user says "I can't select Web API" or "it's not there," ask them to scroll down in the modal — the list may have scroll overflow. The Web API entry should be the top/default option.

## Login session key vs. Client ID

The user may confuse a **Spotify Developer login session** key (from browser devtools/localStorage) with the **Client ID** they need to paste.

What the user needs:
- **Client ID** — found on the **Settings** page of the created app (not the dashboard homepage). Format: `1a2b3c4d5e6f...` (32 hex chars).
- **NOT** the session cookie or token from logging into developer.spotify.com.

Guide them step by step:
1. Go to https://developer.spotify.com/dashboard
2. Log in with Spotify account
3. Click the app name
4. Click **Settings** (gear icon)
5. Copy the **Client ID** field
6. Paste into the `hermes auth spotify` prompt

## Redirect URI mismatch

The OAuth flow **will fail silently** (browser shows an error page) if the Redirect URI in the Spotify app settings doesn't match exactly what `hermes auth spotify` expects.

The Hermes tool uses:
```
http://127.0.0.1:43827/spotify/callback
```

This must be added under **Redirect URIs** in the Spotify app Settings. Common mistakes:
- Using `localhost` instead of `127.0.0.1`
- Missing trailing path `/spotify/callback`
- Trailing slash
- HTTP vs HTTPS (must be HTTP for localhost)

After saving the redirect URI, it can take a minute to propagate. If auth fails, have the user double-check this field.
