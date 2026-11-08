/* ============================================================================
   NSR HUD Ultimate — Behavioral Unit Tests for NUI Localization & Validation
   File: tests/test_nui_runtime.js
   Run with: node tests/test_nui_runtime.js
   ============================================================================ */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');

// Minimal DOM & Window mock for executing NUI modules in Node
const bodyClasses = new Set();
const mockWindow = {
    document: {
        documentElement: { lang: 'en', dir: 'ltr', style: { setProperty: () => {} } },
        body: {
            classList: {
                add: (c) => bodyClasses.add(c),
                remove: (c) => bodyClasses.delete(c),
                toggle: (c, force) => {
                    if (force === undefined) {
                        if (bodyClasses.has(c)) bodyClasses.delete(c); else bodyClasses.add(c);
                    } else if (force) {
                        bodyClasses.add(c);
                    } else {
                        bodyClasses.delete(c);
                    }
                },
                contains: (c) => bodyClasses.has(c)
            },
            setAttribute: () => {}
        },
        querySelectorAll: () => [],
        getElementById: () => null,
        addEventListener: () => {}
    },
    Intl: Intl
};
mockWindow.window = mockWindow;

const context = vm.createContext(mockWindow);

function loadScript(relPath) {
    const code = fs.readFileSync(path.join(ROOT, relPath), 'utf8');
    vm.runInContext(code, context, { filename: relPath });
}

loadScript('html/js/localization.js');
loadScript('html/js/persistence.js');

// 1. Test Localization LTR (English) & Parameter Interpolation
mockWindow.NSRLocaleUI.init({
    locale: 'en',
    isRTL: false,
    dir: 'ltr',
    strings: {
        'notify.cruise_on': 'Cruise control locked at {speed} {unit}.',
        'hud.health': 'Health'
    }
});
assert.strictEqual(mockWindow.document.documentElement.dir, 'ltr');
assert.strictEqual(mockWindow.document.body.classList.contains('rtl-layout'), false);
assert.strictEqual(
    mockWindow.NSRLocaleUI.t('notify.cruise_on', { speed: 120, unit: 'KM/H' }),
    'Cruise control locked at 120 KM/H.'
);
assert.strictEqual(mockWindow.NSRLocaleUI.formatCurrency(1500, '$', 'prefix'), '$1,500');
console.log('[PASS] NUI Localization Engine (English LTR & Interpolation)');

// 2. Test Localization RTL (Arabic)
mockWindow.NSRLocaleUI.init({
    locale: 'ar',
    isRTL: true,
    dir: 'rtl',
    strings: {
        'hud.health': 'الصحة'
    }
});
assert.strictEqual(mockWindow.document.documentElement.dir, 'rtl');
assert.strictEqual(mockWindow.document.body.classList.contains('rtl-layout'), true);
assert.strictEqual(mockWindow.NSRLocaleUI.t('hud.health'), 'الصحة');
console.log('[PASS] NUI Localization Engine (Arabic RTL Layout Activation)');

// 3. Test Profile & Widget Validation / Clamping
const sanitized = mockWindow.NSRPersistenceUI.sanitizeProfile({
    theme: 'neon',
    cinematicMode: 1,
    widgets: {
        health: {
            enabled: true,
            style: 'INVALID_STYLE',
            x: -45.5,
            y: 185.0,
            scale: 9.5,
            opacity: -2.0,
            color: 'javascript:alert(1)'
        }
    },
    vehicle: {
        preset: 'unknown_preset',
        speedUnit: 'mph',
        x: 200,
        y: -10,
        scale: 0.1,
        opacity: 5.0
    },
    carplay: {
        brightness: 999,
        wallpaper: 'invalid_wp'
    }
}, {
    theme: 'midnight',
    widgets: {
        health: { enabled: true, style: 'ring', x: 1.6, y: 91.5, scale: 1.0, opacity: 0.95, color: '#EF4444', showIcon: true, showLabel: false, showValue: true }
    },
    vehicle: {
        preset: 'cyber_digital', speedUnit: 'kmh', x: 76.5, y: 77.0, scale: 1.0, opacity: 0.96,
        primaryColor: '#00E5FF', secondaryColor: '#3B82F6', accentColor: '#EF4444', modules: {}
    }
});

assert.strictEqual(sanitized.widgets.health.style, 'ring');
assert.strictEqual(sanitized.widgets.health.x, 0);
assert.strictEqual(sanitized.widgets.health.y, 96);
assert.strictEqual(sanitized.widgets.health.scale, 2.0);
assert.strictEqual(sanitized.widgets.health.opacity, 0.1);
assert.strictEqual(sanitized.widgets.health.color, '#EF4444');
assert.strictEqual(sanitized.vehicle.preset, 'cyber_digital');
assert.strictEqual(sanitized.vehicle.speedUnit, 'mph');
assert.strictEqual(sanitized.vehicle.x, 95);
assert.strictEqual(sanitized.vehicle.y, 0);
assert.strictEqual(sanitized.vehicle.scale, 0.5);
assert.strictEqual(sanitized.vehicle.opacity, 1.0);
assert.strictEqual(sanitized.carplay.brightness, 100);
assert.strictEqual(sanitized.carplay.wallpaper, 'obsidian');
console.log('[PASS] NUI Persistence & Bounds Sanitizer (Coordinate Clamping & XSS Color Filtering)');
