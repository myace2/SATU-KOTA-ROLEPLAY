/* ============================================================================
   NSR HUD ULTIMATE — GLOBAL THEME, CINEMATIC & AUDIO ENGINE (html/js/settings.js)
   ============================================================================ */

(function (window) {
    'use strict';

    let audioCtx = null;
    let availableThemes = {};

    function setAvailableThemes(themesMap) {
        if (themesMap && typeof themesMap === 'object') {
            availableThemes = themesMap;
        }
    }

    function getAvailableThemes() {
        return availableThemes;
    }

    function applyTheme(themeId) {
        const cleanId = typeof themeId === 'string' ? themeId : 'midnight';
        const themeClasses = [
            'theme-midnight', 'theme-neon', 'theme-minimal',
            'theme-sport', 'theme-luxury', 'theme-tactical'
        ];
        themeClasses.forEach((cls) => document.body.classList.remove(cls));
        document.body.classList.add('theme-' + cleanId);
        document.body.setAttribute('data-theme', cleanId);

        const themeDef = availableThemes[cleanId];
        if (themeDef) {
            const rootStyle = document.documentElement.style;
            if (themeDef.primary) rootStyle.setProperty('--nsr-primary', themeDef.primary);
            if (themeDef.secondary) rootStyle.setProperty('--nsr-secondary', themeDef.secondary);
            if (themeDef.accent) rootStyle.setProperty('--nsr-accent', themeDef.accent);
            if (themeDef.surface) rootStyle.setProperty('--nsr-surface', themeDef.surface);
            if (themeDef.border) rootStyle.setProperty('--nsr-border', themeDef.border);
        }
    }

    function applyCinematicMode(enabled) {
        const overlay = document.getElementById('cinematic-overlay');
        if (!overlay) return;
        overlay.classList.toggle('hidden', !enabled);
    }

    function applyGridOverlay(enabled) {
        const grid = document.getElementById('editor-grid-overlay');
        if (!grid) return;
        grid.classList.toggle('hidden', !enabled);
    }

    function playClickSound(enabled) {
        if (enabled === false) return;
        try {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            if (!AudioContextClass) return;
            if (!audioCtx) {
                audioCtx = new AudioContextClass();
            }
            if (audioCtx.state === 'suspended') {
                audioCtx.resume();
            }
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(640, audioCtx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(320, audioCtx.currentTime + 0.035);
            gain.gain.setValueAtTime(0.035, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.035);
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.04);
        } catch (_) {
            // Ignore audio errors if blocked by browser autoplay policy
        }
    }

    window.NSRSettingsUI = {
        setAvailableThemes: setAvailableThemes,
        getAvailableThemes: getAvailableThemes,
        applyTheme: applyTheme,
        applyCinematicMode: applyCinematicMode,
        applyGridOverlay: applyGridOverlay,
        playClickSound: playClickSound
    };
})(window);
