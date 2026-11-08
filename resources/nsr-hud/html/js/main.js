/* ============================================================================
   NSR HUD ULTIMATE — MASTER NUI CONTROLLER (html/js/main.js)
   Handles Lua <-> NUI messaging, Toast Notifications, & Lifecycle
   ============================================================================ */

(function (window) {
    'use strict';

    let currentProfile = null;
    let masterVisible = true;
    let gamePaused = false;

    function syncRootVisibility() {
        const root = document.getElementById('hud-root');
        if (!root) return;
        const shouldShow = masterVisible && !gamePaused && (!currentProfile || currentProfile.hudVisible !== false);
        root.classList.toggle('hidden', !shouldShow);
    }

    function applyProfile(profile) {
        if (!profile || typeof profile !== 'object') return;
        currentProfile = profile;
        window.NSRSettingsUI.applyTheme(profile.theme || 'midnight');
        window.NSRSettingsUI.applyCinematicMode(Boolean(profile.cinematicMode));
        window.NSRPlayerHudUI.applyLayout(profile.widgets || {});
        window.NSRVehicleHudUI.applyConfig(profile.vehicle || {});
        window.NSRCarPlayUI.applyPreferences(profile.carplay || {});
        syncRootVisibility();
    }

    function showToast(type, message) {
        if (!message) return;
        const container = document.getElementById('toast-container');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = `nsr-toast toast-${type || 'info'}`;
        toast.textContent = String(message);
        container.appendChild(toast);

        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transition = 'opacity 0.25s ease';
            setTimeout(() => toast.remove(), 260);
        }, 3200);
    }

    window.addEventListener('message', (event) => {
        const msg = event.data;
        if (!msg || typeof msg !== 'object') return;

        switch (msg.action) {
            case 'updatePlayerHud':
                window.NSRPlayerHudUI.updateData(msg.data || {});
                if (msg.data && msg.data.clock) {
                    const cpClock = document.getElementById('carplay-clock');
                    if (cpClock) cpClock.textContent = msg.data.clock;
                }
                break;

            case 'updateVehicleHud':
                window.NSRVehicleHudUI.updateTelemetry(msg.data || {});
                window.NSRCarPlayUI.refreshIfOpen();
                break;

            case 'updateSeatbelt':
                if (msg.data && window.NSRVehicleHudUI.setSeatbeltImmediate) {
                    window.NSRVehicleHudUI.setSeatbeltImmediate(Boolean(msg.data.buckled));
                }
                break;

            case 'applyProfile':
                applyProfile(msg.data);
                break;

            case 'openCarPlay':
                window.NSRCarPlayUI.open(msg.data || {});
                break;

            case 'closeCarPlay':
                window.NSRCarPlayUI.close();
                break;

            case 'openEditor':
                window.NSREditorUI.open(msg.data || {});
                break;

            case 'closeEditor':
                window.NSREditorUI.close();
                break;

            case 'setHudVisible':
                masterVisible = Boolean(msg.data && msg.data.visible);
                syncRootVisibility();
                break;

            case 'setPauseState':
                gamePaused = Boolean(msg.data && msg.data.paused);
                syncRootVisibility();
                break;

            case 'notify':
                if (msg.data) {
                    showToast(msg.data.type, msg.data.message);
                }
                break;

            default:
                break;
        }
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (window.NSRCarPlayUI.isOpen()) {
                window.NSRPersistenceUI.postNUI('closeCarPlay', {});
                window.NSRCarPlayUI.close();
            } else if (window.NSREditorUI.isOpen()) {
                window.NSRPersistenceUI.postNUI('cancelEditor', {});
                window.NSREditorUI.close();
            }
        }
    });

    document.addEventListener('DOMContentLoaded', async () => {
        const initData = await window.NSRPersistenceUI.postNUI('nuiReady', {});
        if (initData && !initData.simulated) {
            if (initData.themes) {
                window.NSRSettingsUI.setAvailableThemes(initData.themes);
            }
            if (initData.localization) {
                window.NSRLocaleUI.init(initData.localization);
                window.NSRVehicleHudUI.rebuildLabels();
            }
            if (initData.defaultProfile) {
                window.NSREditorUI.setDefaultProfile(initData.defaultProfile);
            }
            if (initData.profile) {
                applyProfile(initData.profile);
            }
        }
    });

    window.NSRMainUI = {
        getProfile: function () { return currentProfile; },
        setProfile: function (p) { applyProfile(p); },
        showToast: showToast
    };
})(window);
