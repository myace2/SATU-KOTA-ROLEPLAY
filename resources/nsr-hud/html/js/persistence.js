/* ============================================================================
   NSR HUD ULTIMATE — NUI PERSISTENCE & VALIDATION BRIDGE (html/js/persistence.js)
   ============================================================================ */

(function (window) {
    'use strict';

    const WIDGET_IDS = [
        'health', 'armor', 'hunger', 'thirst', 'stamina', 'oxygen', 'stress',
        'voice', 'playerid', 'cash', 'bank', 'job', 'compass', 'location', 'clock'
    ];

    const ALLOWED_STYLES = { ring: true, bar: true, pill: true, hex: true, minimal: true };
    const ALLOWED_PRESETS = {
        aggressive: true,
        modern: true,
        circle: true,
        simple_racing: true,
        simple: true,
        sport: true,
        nfs_heat: true,
        nfs_unbound: true,
        nfs_mostwanted: true,
        cyber_digital: true,
        analog_classic: true,
        sport_gt: true,
        minimal_strip: true
    };

    function clamp(val, min, max) {
        const n = Number(val);
        if (!Number.isFinite(n)) return min;
        return Math.min(max, Math.max(min, n));
    }

    function deepClone(obj) {
        if (obj === null || typeof obj !== 'object') return obj;
        try {
            return JSON.parse(JSON.stringify(obj));
        } catch (_) {
            return {};
        }
    }

    function isValidHex(color) {
        return typeof color === 'string' && /^#[0-9A-Fa-f]{6}$/.test(color);
    }

    function getResourceName() {
        if (typeof window.GetParentResourceName === 'function') {
            return window.GetParentResourceName();
        }
        return 'nsr-hud';
    }

    async function postNUI(endpoint, payload) {
        if (typeof window.GetParentResourceName !== 'function') {
            return { ok: true, simulated: true };
        }
        try {
            const resp = await fetch(`https://${getResourceName()}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(payload || {})
            });
            return await resp.json();
        } catch (_) {
            return { ok: false };
        }
    }

    function sanitizeWidget(w, fallback) {
        const def = fallback || {
            enabled: true,
            style: 'ring',
            x: 16.2,
            y: 92.0,
            customPos: false,
            scale: 1.0,
            opacity: 0.95,
            color: '#00E5FF',
            showIcon: true,
            showLabel: false,
            showValue: true
        };
        if (!w || typeof w !== 'object') return deepClone(def);
        return {
            enabled: w.enabled === undefined ? def.enabled : Boolean(w.enabled),
            style: ALLOWED_STYLES[w.style] ? w.style : def.style,
            x: Number(clamp(w.x !== undefined ? w.x : def.x, 0.0, 96.0).toFixed(2)),
            y: Number(clamp(w.y !== undefined ? w.y : def.y, 0.0, 96.0).toFixed(2)),
            customPos: Boolean(w.customPos),
            scale: Number(clamp(w.scale !== undefined ? w.scale : def.scale, 0.5, 2.0).toFixed(2)),
            opacity: Number(clamp(w.opacity !== undefined ? w.opacity : def.opacity, 0.1, 1.0).toFixed(2)),
            color: isValidHex(w.color) ? w.color : def.color,
            showIcon: w.showIcon === undefined ? def.showIcon : Boolean(w.showIcon),
            showLabel: w.showLabel === undefined ? def.showLabel : Boolean(w.showLabel),
            showValue: w.showValue === undefined ? def.showValue : Boolean(w.showValue)
        };
    }

    function sanitizeProfile(raw, defaultProfile) {
        const base = deepClone(defaultProfile || {});
        if (!raw || typeof raw !== 'object') return base;

        const out = {
            schemaVersion: 3,
            theme: typeof raw.theme === 'string' ? raw.theme : (base.theme || 'midnight'),
            hudVisible: raw.hudVisible === undefined ? true : Boolean(raw.hudVisible),
            cinematicMode: Boolean(raw.cinematicMode),
            widgets: {},
            vehicle: deepClone(base.vehicle || {}),
            carplay: deepClone(base.carplay || { brightness: 100, compactMode: false, uiSounds: true, wallpaper: 'obsidian' }),
            presets: []
        };

        const rawWidgets = (raw.widgets && typeof raw.widgets === 'object') ? raw.widgets : {};
        const baseWidgets = (base.widgets && typeof base.widgets === 'object') ? base.widgets : {};

        WIDGET_IDS.forEach((id) => {
            out.widgets[id] = sanitizeWidget(rawWidgets[id], baseWidgets[id]);
        });

        if (raw.vehicle && typeof raw.vehicle === 'object') {
            const rv = raw.vehicle;
            const bv = out.vehicle;
            bv.preset = ALLOWED_PRESETS[rv.preset] ? rv.preset : (bv.preset || 'aggressive');
            bv.speedUnit = (rv.speedUnit === 'mph') ? 'mph' : 'kmh';
            bv.x = Number(clamp(rv.x !== undefined ? rv.x : bv.x, 0.0, 95.0).toFixed(2));
            bv.y = Number(clamp(rv.y !== undefined ? rv.y : bv.y, 0.0, 95.0).toFixed(2));
            bv.scale = Number(clamp(rv.scale !== undefined ? rv.scale : bv.scale, 0.5, 2.0).toFixed(2));
            bv.opacity = Number(clamp(rv.opacity !== undefined ? rv.opacity : bv.opacity, 0.1, 1.0).toFixed(2));
            bv.primaryColor = isValidHex(rv.primaryColor) ? rv.primaryColor : (bv.primaryColor || '#FFFFFF');
            bv.secondaryColor = isValidHex(rv.secondaryColor) ? rv.secondaryColor : (bv.secondaryColor || '#10B981');
            bv.accentColor = isValidHex(rv.accentColor) ? rv.accentColor : (bv.accentColor || '#EF4444');
            bv.animations = rv.animations === undefined ? true : Boolean(rv.animations);

            bv.modules = bv.modules || {};
            if (rv.modules && typeof rv.modules === 'object') {
                Object.keys(rv.modules).forEach((mKey) => {
                    bv.modules[mKey] = Boolean(rv.modules[mKey]);
                });
            }
        }

        if (raw.carplay && typeof raw.carplay === 'object') {
            out.carplay.brightness = Math.round(clamp(raw.carplay.brightness || 100, 40, 100));
            out.carplay.compactMode = Boolean(raw.carplay.compactMode);
            out.carplay.uiSounds = raw.carplay.uiSounds === undefined ? true : Boolean(raw.carplay.uiSounds);
            const wp = raw.carplay.wallpaper;
            out.carplay.wallpaper = ['obsidian', 'carbon', 'aurora', 'crimson'].includes(wp) ? wp : 'obsidian';
        }

        if (Array.isArray(raw.presets)) {
            out.presets = raw.presets.slice(0, 5).filter((p) => p && typeof p.name === 'string' && p.name.trim().length > 0);
        }

        return out;
    }

    window.NSRPersistenceUI = {
        WIDGET_IDS: WIDGET_IDS,
        clamp: clamp,
        deepClone: deepClone,
        postNUI: postNUI,
        sanitizeWidget: sanitizeWidget,
        sanitizeProfile: sanitizeProfile
    };
})(window);
