# NSR HUD Ultimate — Multi-Language & RTL Localization Guide

## 1. Configuration-Only Design (`Config.Locale`)

In accordance with strict server-branding requirements, **language selection is controlled exclusively via `config.lua`**:

```lua
Config.Locale = 'en'
```

There is **no** language dropdown, toggle, or selector inside the HUD Editor, Settings panel, or CarPlay interface. Changing `Config.Locale` in `config.lua` and restarting `nsr-hud` immediately updates all server notifications, client messages, HUD labels, editor controls, and CarPlay applications.

## 2. Built-In Languages (239 Keys Each — 100% Parity)

| Code | Language | File Path | Layout Direction |
| :--- | :--- | :--- | :--- |
| `'en'` | English (Default & Fallback) | `locales/en.lua` | Left-to-Right (`ltr`) |
| `'ar'` | Arabic (العربية) | `locales/ar.lua` | **Right-to-Left (`rtl`)** |
| `'fr'` | French (Français) | `locales/fr.lua` | Left-to-Right (`ltr`) |
| `'de'` | German (Deutsch) | `locales/de.lua` | Left-to-Right (`ltr`) |
| `'es'` | Spanish (Español) | `locales/es.lua` | Left-to-Right (`ltr`) |
| `'pt'` | Portuguese (Português) | `locales/pt.lua` | Left-to-Right (`ltr`) |
| `'tr'` | Turkish (Türkçe) | `locales/tr.lua` | Left-to-Right (`ltr`) |
| `'it'` | Italian (Italiano) | `locales/it.lua` | Left-to-Right (`ltr`) |

## 3. Right-to-Left (RTL) Behavior for Arabic (`Config.Locale = 'ar'`)

When `Config.Locale = 'ar'` is selected:
1. `NSRLocale.GetActiveBundle()` sends `isRTL = true` and `dir = 'rtl'` to the NUI during the `nuiReady` handshake.
2. `html/js/localization.js` sets `document.documentElement.dir = 'rtl'`, `document.documentElement.lang = 'ar'`, and adds `.rtl-layout` to `document.body`.
3. `html/css/main.css` flips flex/grid alignments, aligns labels and property rows right-to-left, and docks the HUD Studio inspector panel on the left side of the screen so it does not collide with right-aligned HUD elements.

## 4. Fallback Safety

If a server owner configures an unknown locale code or omits a key in a custom translation file:
- `shared/locale.lua` logs a warning and falls back to `'en'` (`locales/en.lua`).
- Any missing individual key in a non-English locale automatically falls back to the English phrase from `locales/en.lua` without crashing or showing `nil`.

## 5. How to Add a New Language

1. Duplicate `locales/en.lua` to `locales/nl.lua` (for Dutch, for example) and change the header call to `NSRLocale.Register('nl', { ... })`.
2. Add `'nl'` to `NSRConstants.SupportedLocales` in `shared/constants.lua` (`nl = { code = 'nl', name = 'Nederlands', rtl = false }`).
3. Add `'locales/nl.lua'` to `shared_scripts` in `fxmanifest.lua`.
4. Set `Config.Locale = 'nl'` in `config.lua`.
