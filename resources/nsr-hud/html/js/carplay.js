/* ============================================================================
   NSR HUD ULTIMATE — NSR CARPLAY INFOTAINMENT CONTROLLER (html/js/carplay.js)
   6 Applications: Home, Radio, Navigation, Vehicle Info, Controls, Settings
   ============================================================================ */

(function (window) {
    'use strict';

    let isOpen = false;
    let activeApp = 'home';
    let isDriver = true;
    let enabledApps = { home: true, radio: true, navigation: true, telemetry: true, controls: true, settings: true };
    let radioData = { powered: false, currentId: 'OFF', currentLabel: '', stations: [] };
    let navData = { active: false, distance: '0.0 km' };
    let quickLocations = [];
    let carplayPrefs = { brightness: 100, compactMode: false, uiSounds: true, wallpaper: 'obsidian' };

    function applyPreferences(prefs) {
        if (!prefs || typeof prefs !== 'object') return;
        carplayPrefs = Object.assign({}, carplayPrefs, prefs);
        const bezel = document.getElementById('carplay-bezel');
        if (!bezel) return;

        bezel.classList.toggle('compact-mode', Boolean(carplayPrefs.compactMode));
        bezel.style.filter = `brightness(${window.NSRPersistenceUI.clamp(carplayPrefs.brightness, 40, 100)}%)`;

        ['obsidian', 'carbon', 'aurora', 'crimson'].forEach((wp) => {
            bezel.classList.remove('wallpaper-' + wp);
        });
        bezel.classList.add('wallpaper-' + (carplayPrefs.wallpaper || 'obsidian'));
    }

    function open(payload) {
        isOpen = true;
        if (payload && typeof payload === 'object') {
            isDriver = payload.isDriver !== false;
            if (payload.apps) enabledApps = payload.apps;
            if (payload.radio) radioData = payload.radio;
            if (payload.navigation) navData = payload.navigation;
            if (Array.isArray(payload.locations)) quickLocations = payload.locations;
        }

        const modal = document.getElementById('carplay-modal');
        if (modal) modal.classList.remove('hidden');

        const roleBadge = document.getElementById('carplay-role-badge');
        if (roleBadge) {
            roleBadge.textContent = window.NSRLocaleUI.t(isDriver ? 'carplay.driver_badge' : 'carplay.passenger_badge');
        }

        // Update dock button visibility based on server config
        document.querySelectorAll('.carplay-dock-btn').forEach((btn) => {
            const appKey = btn.getAttribute('data-app');
            const allowed = enabledApps[appKey] !== false;
            btn.classList.toggle('hidden', !allowed);
        });

        if (enabledApps[activeApp] === false) {
            activeApp = 'home';
        }
        switchApp(activeApp);
    }

    function close() {
        isOpen = false;
        const modal = document.getElementById('carplay-modal');
        if (modal) modal.classList.add('hidden');
    }

    function switchApp(appName) {
        activeApp = appName;
        document.querySelectorAll('.carplay-dock-btn').forEach((btn) => {
            btn.classList.toggle('active', btn.getAttribute('data-app') === appName);
        });
        renderViewport();
    }

    function renderViewport() {
        const viewport = document.getElementById('carplay-viewport');
        if (!viewport) return;
        const t = window.NSRLocaleUI.t;
        const vData = window.NSRVehicleHudUI.getLastTelemetry() || {};

        if (activeApp === 'home') {
            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.brand')}</div>
                        <div class="cp-app-subtitle">${t('app.brand_subtitle')}</div>
                    </div>
                </div>
                <div class="cp-grid-2">
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.quick_status')}</div>
                        <div class="editor-prop-row">
                            <span>${t('vehicle.cluster_title')}</span>
                            <strong>${vData.speed || 0} ${(vData.unit || 'kmh').toUpperCase()} (${vData.gear || 'N'})</strong>
                        </div>
                        <div class="editor-prop-row">
                            <span>${t('vehicle.fuel')}</span>
                            <strong>${vData.fuel !== undefined && vData.fuel !== null ? vData.fuel + '%' : t('app.unavailable')}</strong>
                        </div>
                        <div class="editor-prop-row">
                            <span>${t('vehicle.engine')}</span>
                            <strong>${vData.engineHealth !== undefined && vData.engineHealth !== null ? vData.engineHealth + '%' : t('app.unavailable')}</strong>
                        </div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.nav_radio')}</div>
                        <div style="font-size:15px;font-weight:700;">${radioData.currentLabel || t('carplay.radio_no_signal')}</div>
                        <div class="cp-input-row">
                            <button type="button" class="cp-action-btn" data-radio-cmd="prev">${t('carplay.radio_prev')}</button>
                            <button type="button" class="cp-action-btn ${radioData.powered ? 'active' : ''}" data-radio-cmd="toggle">${t('carplay.radio_toggle')}</button>
                            <button type="button" class="cp-action-btn" data-radio-cmd="next">${t('carplay.radio_next')}</button>
                        </div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.nav_navigation')}</div>
                        <div style="font-size:14px;font-weight:700;">
                            ${navData.active ? t('carplay.nav_active_waypoint') : t('carplay.nav_no_waypoint')}
                        </div>
                        <div style="font-size:12px;color:var(--nsr-text-muted);">
                            ${navData.active ? t('carplay.nav_distance', { distance: navData.distance }) : t('carplay.nav_subtitle')}
                        </div>
                        <button type="button" class="cp-action-btn" data-open-app="navigation">${t('carplay.nav_set_waypoint')}</button>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.quick_actions')}</div>
                        <div class="cp-grid-2">
                            <button type="button" class="cp-action-btn ${vData.engineRunning ? 'active' : ''}" data-veh-action="toggle_engine" ${!isDriver ? 'disabled' : ''}>
                                <span>${t('carplay.ctrl_engine')}</span>
                            </button>
                            <button type="button" class="cp-action-btn ${vData.locked ? 'active' : ''}" data-veh-action="toggle_lock" ${!isDriver ? 'disabled' : ''}>
                                <span>${t('carplay.ctrl_locks')}</span>
                            </button>
                            <button type="button" class="cp-action-btn ${vData.lightsOn ? 'active' : ''}" data-veh-action="toggle_lights" ${!isDriver ? 'disabled' : ''}>
                                <span>${t('carplay.ctrl_lights')}</span>
                            </button>
                            <button type="button" class="cp-action-btn ${(vData.indicators === 3) ? 'active' : ''}" data-veh-action="toggle_hazards" ${!isDriver ? 'disabled' : ''}>
                                <span>${t('carplay.ctrl_hazards')}</span>
                            </button>
                        </div>
                    </div>
                </div>
            `;
        } else if (activeApp === 'radio') {
            const stationsHtml = (radioData.stations || []).map((st) => {
                const isCurr = radioData.powered && radioData.currentId === st.id;
                return `<button type="button" class="cp-action-btn ${isCurr ? 'active' : ''}" data-station-id="${st.id}">
                    <span>${st.label}</span>
                </button>`;
            }).join('');

            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.radio_title')}</div>
                        <div class="cp-app-subtitle">${radioData.powered ? t('carplay.radio_power_on') : t('carplay.radio_power_off')} — ${radioData.currentLabel || ''}</div>
                    </div>
                    <div class="cp-input-row">
                        <button type="button" class="cp-action-btn" data-radio-cmd="prev">${t('carplay.radio_prev')}</button>
                        <button type="button" class="cp-action-btn ${radioData.powered ? 'active' : ''}" data-radio-cmd="toggle">${t('carplay.radio_toggle')}</button>
                        <button type="button" class="cp-action-btn" data-radio-cmd="next">${t('carplay.radio_next')}</button>
                    </div>
                </div>
                <div class="cp-card">
                    <div class="cp-card-title">${t('carplay.radio_stations_list')}</div>
                    <div class="cp-station-list">${stationsHtml}</div>
                </div>
            `;
        } else if (activeApp === 'navigation') {
            const destButtons = quickLocations.map((loc) => {
                const lbl = t(loc.labelKey);
                return `<button type="button" class="cp-action-btn" data-wp-x="${loc.x}" data-wp-y="${loc.y}" data-wp-label="${lbl}">
                    <span>${lbl}</span>
                    <span>➤</span>
                </button>`;
            }).join('');

            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.nav_title')}</div>
                        <div class="cp-app-subtitle">${t('carplay.nav_subtitle')}</div>
                    </div>
                    <button type="button" id="cp-clear-wp-btn" class="cp-action-btn">${t('carplay.nav_clear')}</button>
                </div>
                <div class="cp-grid-2">
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.nav_quick_destinations')}</div>
                        <div style="display:flex;flex-direction:column;gap:7px;">${destButtons}</div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.nav_custom_coords')}</div>
                        <div class="cp-input-row">
                            <input type="number" id="cp-nav-x" class="cp-input" placeholder="${t('carplay.nav_coord_x')}" step="0.1" />
                            <input type="number" id="cp-nav-y" class="cp-input" placeholder="${t('carplay.nav_coord_y')}" step="0.1" />
                        </div>
                        <button type="button" id="cp-set-custom-wp" class="cp-action-btn">${t('carplay.nav_set_waypoint')}</button>
                        <div style="margin-top:8px;font-size:12px;color:var(--nsr-text-muted);">
                            ${navData.active ? t('carplay.nav_distance', { distance: navData.distance }) : t('carplay.nav_no_waypoint')}
                        </div>
                    </div>
                </div>
            `;
        } else if (activeApp === 'telemetry') {
            const catKey = 'vehicle.category_' + (vData.category || 'car');
            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.telemetry_title')}</div>
                        <div class="cp-app-subtitle">${t(catKey)} • ${t('carplay.telemetry_plate')}: ${vData.plate || '---'}</div>
                    </div>
                </div>
                <div class="cp-grid-3">
                    <div class="cp-card">
                        <div class="cp-card-title">${t('vehicle.engine')}</div>
                        <div style="font-size:22px;font-weight:800;">${vData.engineHealth !== undefined && vData.engineHealth !== null ? vData.engineHealth + '%' : '100%'}</div>
                        <div style="font-size:11px;color:var(--nsr-text-muted);">${vData.engineRunning ? t('carplay.telemetry_engine_running') : t('carplay.telemetry_engine_stopped')}</div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('vehicle.fuel')}</div>
                        <div style="font-size:22px;font-weight:800;">${vData.fuel !== undefined && vData.fuel !== null ? vData.fuel + '%' : t('app.unavailable')}</div>
                        <div style="font-size:11px;color:var(--nsr-text-muted);">${t('carplay.telemetry_oil_temp')}: ${vData.engineTemp || 75}°C</div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('vehicle.body')}</div>
                        <div style="font-size:22px;font-weight:800;">${vData.bodyHealth !== undefined && vData.bodyHealth !== null ? vData.bodyHealth + '%' : '100%'}</div>
                        <div style="font-size:11px;color:var(--nsr-text-muted);">${vData.tiresBurst ? t('carplay.telemetry_tires_damaged') : t('carplay.telemetry_tires_ok')}</div>
                    </div>
                </div>
            `;
        } else if (activeApp === 'controls') {
            const doors = Array.isArray(vData.doors) ? vData.doors : [false, false, false, false, false, false];
            const disAttr = !isDriver ? 'disabled' : '';
            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.controls_title')}</div>
                        <div class="cp-app-subtitle">${t('carplay.controls_driver_notice')}</div>
                    </div>
                </div>
                <div class="cp-grid-2">
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.doors_section')}</div>
                        <div class="cp-grid-2">
                            <button type="button" class="cp-action-btn ${doors[0] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="0" ${disAttr}>${t('carplay.door_fl')}</button>
                            <button type="button" class="cp-action-btn ${doors[1] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="1" ${disAttr}>${t('carplay.door_fr')}</button>
                            <button type="button" class="cp-action-btn ${doors[2] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="2" ${disAttr}>${t('carplay.door_rl')}</button>
                            <button type="button" class="cp-action-btn ${doors[3] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="3" ${disAttr}>${t('carplay.door_rr')}</button>
                            <button type="button" class="cp-action-btn ${doors[4] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="4" ${disAttr}>${t('carplay.door_hood')}</button>
                            <button type="button" class="cp-action-btn ${doors[5] ? 'active' : ''}" data-veh-action="toggle_door" data-veh-index="5" ${disAttr}>${t('carplay.door_trunk')}</button>
                        </div>
                    </div>
                    <div class="cp-card">
                        <div class="cp-card-title">${t('carplay.windows_section')} & ${t('carplay.seats_section')}</div>
                        <div class="cp-grid-2">
                            <button type="button" class="cp-action-btn" data-veh-action="toggle_window" data-veh-index="0">${t('carplay.win_fl')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="toggle_window" data-veh-index="1">${t('carplay.win_fr')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="toggle_window" data-veh-index="2">${t('carplay.win_rl')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="toggle_window" data-veh-index="3">${t('carplay.win_rr')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="switch_seat" data-veh-index="-1">${t('carplay.seat_driver')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="switch_seat" data-veh-index="0">${t('carplay.seat_pass')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="switch_seat" data-veh-index="1">${t('carplay.seat_rl')}</button>
                            <button type="button" class="cp-action-btn" data-veh-action="switch_seat" data-veh-index="2">${t('carplay.seat_rr')}</button>
                        </div>
                    </div>
                </div>
            `;
        } else if (activeApp === 'settings') {
            // Note: Strictly NO language selector inside CarPlay settings
            viewport.innerHTML = `
                <div class="cp-app-header">
                    <div>
                        <div class="cp-app-title">${t('carplay.settings_title')}</div>
                    </div>
                </div>
                <div class="cp-card">
                    <div class="editor-prop-row">
                        <label>${t('carplay.settings_brightness')} (${carplayPrefs.brightness}%)</label>
                        <input type="range" id="cp-pref-brightness" class="editor-range" min="40" max="100" value="${carplayPrefs.brightness}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('carplay.settings_compact')}</label>
                        <input type="checkbox" id="cp-pref-compact" ${carplayPrefs.compactMode ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('carplay.settings_sounds')}</label>
                        <input type="checkbox" id="cp-pref-sounds" ${carplayPrefs.uiSounds ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('carplay.settings_wallpaper')}</label>
                        <select id="cp-pref-wallpaper" class="editor-select">
                            <option value="obsidian" ${carplayPrefs.wallpaper === 'obsidian' ? 'selected' : ''}>${t('carplay.wp_obsidian')}</option>
                            <option value="carbon" ${carplayPrefs.wallpaper === 'carbon' ? 'selected' : ''}>${t('carplay.wp_carbon')}</option>
                            <option value="aurora" ${carplayPrefs.wallpaper === 'aurora' ? 'selected' : ''}>${t('carplay.wp_aurora')}</option>
                            <option value="crimson" ${carplayPrefs.wallpaper === 'crimson' ? 'selected' : ''}>${t('carplay.wp_crimson')}</option>
                        </select>
                    </div>
                </div>
            `;
        }

        bindViewportEvents(viewport);
    }

    function bindViewportEvents(viewport) {
        viewport.querySelectorAll('[data-open-app]').forEach((btn) => {
            btn.addEventListener('click', () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                switchApp(btn.getAttribute('data-open-app'));
            });
        });

        viewport.querySelectorAll('[data-veh-action]').forEach((btn) => {
            btn.addEventListener('click', async () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                const action = btn.getAttribute('data-veh-action');
                const idxRaw = btn.getAttribute('data-veh-index');
                const index = idxRaw !== null ? Number(idxRaw) : undefined;
                await window.NSRPersistenceUI.postNUI('carplayAction', { action: action, index: index });
                setTimeout(renderViewport, 120);
            });
        });

        viewport.querySelectorAll('[data-radio-cmd]').forEach((btn) => {
            btn.addEventListener('click', async () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                const cmd = btn.getAttribute('data-radio-cmd');
                const res = await window.NSRPersistenceUI.postNUI('carplayRadio', { command: cmd });
                if (res && res.radio) {
                    radioData = res.radio;
                    renderViewport();
                }
            });
        });

        viewport.querySelectorAll('[data-station-id]').forEach((btn) => {
            btn.addEventListener('click', async () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                const stId = btn.getAttribute('data-station-id');
                const res = await window.NSRPersistenceUI.postNUI('carplayRadio', { command: 'station', stationId: stId });
                if (res && res.radio) {
                    radioData = res.radio;
                    renderViewport();
                }
            });
        });

        viewport.querySelectorAll('[data-wp-x]').forEach((btn) => {
            btn.addEventListener('click', async () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                const x = Number(btn.getAttribute('data-wp-x'));
                const y = Number(btn.getAttribute('data-wp-y'));
                const label = btn.getAttribute('data-wp-label');
                const res = await window.NSRPersistenceUI.postNUI('carplayWaypoint', { command: 'set', x: x, y: y, label: label });
                if (res && res.navigation) {
                    navData = res.navigation;
                    renderViewport();
                }
            });
        });

        const clearWpBtn = viewport.querySelector('#cp-clear-wp-btn');
        if (clearWpBtn) {
            clearWpBtn.addEventListener('click', async () => {
                const res = await window.NSRPersistenceUI.postNUI('carplayWaypoint', { command: 'clear' });
                if (res && res.navigation) {
                    navData = res.navigation;
                    renderViewport();
                }
            });
        }

        const customWpBtn = viewport.querySelector('#cp-set-custom-wp');
        if (customWpBtn) {
            customWpBtn.addEventListener('click', async () => {
                const xVal = parseFloat(viewport.querySelector('#cp-nav-x').value);
                const yVal = parseFloat(viewport.querySelector('#cp-nav-y').value);
                const res = await window.NSRPersistenceUI.postNUI('carplayWaypoint', { command: 'set', x: xVal, y: yVal });
                if (res && res.navigation) {
                    navData = res.navigation;
                    renderViewport();
                }
            });
        }

        // Settings bindings
        const brInput = viewport.querySelector('#cp-pref-brightness');
        if (brInput) {
            brInput.addEventListener('input', (e) => {
                carplayPrefs.brightness = Number(e.target.value);
                applyPreferences(carplayPrefs);
                window.NSRPersistenceUI.postNUI('saveCarPlayPrefs', carplayPrefs);
            });
        }

        const compInput = viewport.querySelector('#cp-pref-compact');
        if (compInput) {
            compInput.addEventListener('change', (e) => {
                carplayPrefs.compactMode = Boolean(e.target.checked);
                applyPreferences(carplayPrefs);
                window.NSRPersistenceUI.postNUI('saveCarPlayPrefs', carplayPrefs);
            });
        }

        const sndInput = viewport.querySelector('#cp-pref-sounds');
        if (sndInput) {
            sndInput.addEventListener('change', (e) => {
                carplayPrefs.uiSounds = Boolean(e.target.checked);
                applyPreferences(carplayPrefs);
                window.NSRPersistenceUI.postNUI('saveCarPlayPrefs', carplayPrefs);
            });
        }

        const wpSelect = viewport.querySelector('#cp-pref-wallpaper');
        if (wpSelect) {
            wpSelect.addEventListener('change', (e) => {
                carplayPrefs.wallpaper = e.target.value;
                applyPreferences(carplayPrefs);
                window.NSRPersistenceUI.postNUI('saveCarPlayPrefs', carplayPrefs);
            });
        }
    }

    function bindDockEvents() {
        document.querySelectorAll('.carplay-dock-btn').forEach((btn) => {
            btn.addEventListener('click', () => {
                window.NSRSettingsUI.playClickSound(carplayPrefs.uiSounds);
                switchApp(btn.getAttribute('data-app'));
            });
        });

        const closeBtn = document.getElementById('carplay-close-btn');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => {
                window.NSRPersistenceUI.postNUI('closeCarPlay', {});
                close();
            });
        }
    }

    document.addEventListener('DOMContentLoaded', bindDockEvents);

    window.NSRCarPlayUI = {
        open: open,
        close: close,
        isOpen: function () { return isOpen; },
        applyPreferences: applyPreferences,
        refreshIfOpen: function () {
            if (isOpen && (activeApp === 'home' || activeApp === 'telemetry')) {
                renderViewport();
            }
        }
    };
})(window);
