/* ============================================================================
   NSR HUD ULTIMATE — DRAG-AND-DROP HUD STUDIO EDITOR (html/js/editor.js)
   Features:
   - Opens centered on screen so top-right & bottom-left widgets are never blocked
   - Draggable studio window (grab header to move menu anywhere)
   - Smooth 60fps canvas widget dragging & non-destructive range sliders
   ============================================================================ */

(function (window) {
    'use strict';

    let isOpen = false;
    let activeTab = 'widgets';
    let selectedWidgetId = 'health';
    let workingProfile = null;
    let defaultProfile = null;
    let showGrid = true;
    let previewVehOnFoot = true;
    let dragState = null;
    let panelInitializedPos = false;

    function setDefaultProfile(defProf) {
        defaultProfile = window.NSRPersistenceUI.deepClone(defProf);
    }

    function centerEditorPanel() {
        const panel = document.getElementById('editor-panel');
        if (!panel) return;
        const pw = 410;
        const ph = Math.min(580, window.innerHeight - 48);
        const leftPx = Math.max(16, Math.round((window.innerWidth - pw) / 2));
        const topPx = Math.max(16, Math.round((window.innerHeight - ph) / 2));
        panel.style.left = `${leftPx}px`;
        panel.style.top = `${topPx}px`;
        panel.style.right = 'auto';
    }

    function open(payload) {
        isOpen = true;
        activeTab = (payload && payload.tab) || 'widgets';
        workingProfile = window.NSRPersistenceUI.sanitizeProfile(
            (payload && payload.profile) || window.NSRMainUI.getProfile(),
            defaultProfile
        );

        document.body.classList.add('editor-active');
        window.NSRPlayerHudUI.setEditorMode(true);
        window.NSRVehicleHudUI.setEditorPreview(previewVehOnFoot);
        window.NSRSettingsUI.applyGridOverlay(showGrid);

        const modal = document.getElementById('hud-editor-modal');
        if (modal) modal.classList.remove('hidden');

        if (!panelInitializedPos) {
            centerEditorPanel();
            panelInitializedPos = true;
        }

        highlightSelectedElement();
        switchTab(activeTab);
    }

    function close() {
        isOpen = false;
        dragState = null;
        document.body.classList.remove('editor-active');
        window.NSRPlayerHudUI.setEditorMode(false);
        window.NSRVehicleHudUI.setEditorPreview(false);
        window.NSRSettingsUI.applyGridOverlay(false);

        const panel = document.getElementById('editor-panel');
        if (panel) panel.classList.remove('dragging-canvas-item');

        document.querySelectorAll('.editor-selected').forEach((el) => el.classList.remove('editor-selected'));
        const modal = document.getElementById('hud-editor-modal');
        if (modal) modal.classList.add('hidden');
    }

    function highlightSelectedElement() {
        document.querySelectorAll('.hud-widget, .vehicle-hud-wrapper').forEach((el) => {
            el.classList.remove('editor-selected');
        });
        if (activeTab === 'vehicle') {
            const vWrap = document.getElementById('vehicle-hud-wrapper');
            if (vWrap) vWrap.classList.add('editor-selected');
        } else {
            const target = document.querySelector(`.hud-widget[data-widget-id="${selectedWidgetId}"]`);
            if (target) target.classList.add('editor-selected');
        }
    }

    function applyWorkingChangesLive() {
        if (!workingProfile) return;
        window.NSRSettingsUI.applyTheme(workingProfile.theme);
        window.NSRSettingsUI.applyCinematicMode(workingProfile.cinematicMode);
        window.NSRPlayerHudUI.applyLayout(workingProfile.widgets);
        window.NSRVehicleHudUI.applyConfig(workingProfile.vehicle);
        highlightSelectedElement();
    }

    function switchTab(tabId) {
        activeTab = tabId;
        document.querySelectorAll('.editor-tab-btn').forEach((btn) => {
            btn.classList.toggle('active', btn.getAttribute('data-tab') === tabId);
        });
        highlightSelectedElement();
        renderTabBody();
    }

    function renderTabBody() {
        const container = document.getElementById('editor-tab-body');
        if (!container || !workingProfile) return;
        const t = window.NSRLocaleUI.t;

        if (activeTab === 'widgets') {
            const chipsHtml = window.NSRPersistenceUI.WIDGET_IDS.map((id) => {
                const lbl = t('hud.' + id);
                const isAct = (id === selectedWidgetId);
                return `<button type="button" class="editor-widget-chip ${isAct ? 'active' : ''}" data-select-widget="${id}">${lbl}</button>`;
            }).join('');

            const w = workingProfile.widgets[selectedWidgetId];
            container.innerHTML = `
                <div class="editor-widget-pills">${chipsHtml}</div>
                <div class="editor-prop-group">
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_enabled')}</label>
                        <input type="checkbox" id="ed-w-enabled" ${w.enabled ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_style')}</label>
                        <select id="ed-w-style" class="editor-select">
                            <option value="ring" ${w.style === 'ring' ? 'selected' : ''}>${t('editor.style_ring')}</option>
                            <option value="bar" ${w.style === 'bar' ? 'selected' : ''}>${t('editor.style_bar')}</option>
                            <option value="pill" ${w.style === 'pill' ? 'selected' : ''}>${t('editor.style_pill')}</option>
                            <option value="hex" ${w.style === 'hex' ? 'selected' : ''}>${t('editor.style_hex')}</option>
                            <option value="minimal" ${w.style === 'minimal' ? 'selected' : ''}>${t('editor.style_minimal')}</option>
                        </select>
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_x')} <span id="ed-w-x-val">(${w.x}%)</span></label>
                        <input type="range" id="ed-w-x" class="editor-range" min="0" max="96" step="0.5" value="${w.x}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_y')} <span id="ed-w-y-val">(${w.y}%)</span></label>
                        <input type="range" id="ed-w-y" class="editor-range" min="0" max="96" step="0.5" value="${w.y}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_scale')} <span id="ed-w-scale-val">(${w.scale}x)</span></label>
                        <input type="range" id="ed-w-scale" class="editor-range" min="0.5" max="2.0" step="0.05" value="${w.scale}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_opacity')} <span id="ed-w-opacity-val">(${Math.round(w.opacity * 100)}%)</span></label>
                        <input type="range" id="ed-w-opacity" class="editor-range" min="0.1" max="1.0" step="0.05" value="${w.opacity}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_color')}</label>
                        <input type="color" id="ed-w-color" class="editor-color" value="${w.color}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_show_icon')}</label>
                        <input type="checkbox" id="ed-w-icon" ${w.showIcon ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_show_label')}</label>
                        <input type="checkbox" id="ed-w-label" ${w.showLabel ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_show_value')}</label>
                        <input type="checkbox" id="ed-w-value" ${w.showValue ? 'checked' : ''} />
                    </div>
                    <button type="button" id="ed-reset-single-widget" class="btn-editor btn-secondary">${t('editor.reset_widget')}</button>
                </div>
            `;
            bindWidgetInspectorEvents(container);
        } else if (activeTab === 'vehicle') {
            const v = workingProfile.vehicle;
            const mods = v.modules || {};
            const modKeys = [
                { k: 'rpm', l: 'vehicle.rpm' },
                { k: 'gear', l: 'vehicle.gear' },
                { k: 'fuel', l: 'vehicle.fuel' },
                { k: 'engine', l: 'vehicle.engine' },
                { k: 'body', l: 'vehicle.body' },
                { k: 'seatbelt', l: 'vehicle.seatbelt' },
                { k: 'lights', l: 'vehicle.lights' },
                { k: 'indicators', l: 'vehicle.indicators' },
                { k: 'handbrake', l: 'vehicle.handbrake' },
                { k: 'locks', l: 'vehicle.locks' },
                { k: 'nitro', l: 'vehicle.nitro' },
                { k: 'cruise', l: 'vehicle.cruise' }
            ];

            const modsHtml = modKeys.map((item) => `
                <div class="editor-prop-row">
                    <label>${t(item.l)}</label>
                    <input type="checkbox" data-veh-mod="${item.k}" ${mods[item.k] !== false ? 'checked' : ''} />
                </div>
            `).join('');

            container.innerHTML = `
                <div class="editor-prop-group">
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_preview_on_foot')}</label>
                        <input type="checkbox" id="ed-v-preview" ${previewVehOnFoot ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_preset')}</label>
                        <select id="ed-v-preset" class="editor-select">
                            <option value="aggressive" ${v.preset === 'aggressive' ? 'selected' : ''}>${t('vehicle.preset_aggressive')}</option>
                            <option value="modern" ${v.preset === 'modern' ? 'selected' : ''}>${t('vehicle.preset_modern')}</option>
                            <option value="circle" ${v.preset === 'circle' ? 'selected' : ''}>${t('vehicle.preset_circle')}</option>
                            <option value="simple_racing" ${v.preset === 'simple_racing' ? 'selected' : ''}>${t('vehicle.preset_simple_racing')}</option>
                            <option value="simple" ${v.preset === 'simple' ? 'selected' : ''}>${t('vehicle.preset_simple')}</option>
                            <option value="sport" ${v.preset === 'sport' ? 'selected' : ''}>${t('vehicle.preset_sport')}</option>
                            <option value="nfs_heat" ${v.preset === 'nfs_heat' ? 'selected' : ''}>${t('vehicle.preset_nfs_heat')}</option>
                        </select>
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_unit')}</label>
                        <select id="ed-v-unit" class="editor-select">
                            <option value="kmh" ${v.speedUnit === 'kmh' ? 'selected' : ''}>${t('vehicle.speed_kmh')}</option>
                            <option value="mph" ${v.speedUnit === 'mph' ? 'selected' : ''}>${t('vehicle.speed_mph')}</option>
                        </select>
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_x')} <span id="ed-v-x-val">(${v.x}%)</span></label>
                        <input type="range" id="ed-v-x" class="editor-range" min="0" max="95" step="0.5" value="${v.x}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_y')} <span id="ed-v-y-val">(${v.y}%)</span></label>
                        <input type="range" id="ed-v-y" class="editor-range" min="0" max="95" step="0.5" value="${v.y}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_scale')} <span id="ed-v-scale-val">(${v.scale}x)</span></label>
                        <input type="range" id="ed-v-scale" class="editor-range" min="0.5" max="2.0" step="0.05" value="${v.scale}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.prop_opacity')} <span id="ed-v-opacity-val">(${Math.round(v.opacity * 100)}%)</span></label>
                        <input type="range" id="ed-v-opacity" class="editor-range" min="0.1" max="1.0" step="0.05" value="${v.opacity}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_primary_color')}</label>
                        <input type="color" id="ed-v-c1" class="editor-color" value="${v.primaryColor}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_secondary_color')}</label>
                        <input type="color" id="ed-v-c2" class="editor-color" value="${v.secondaryColor}" />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.veh_accent_color')}</label>
                        <input type="color" id="ed-v-c3" class="editor-color" value="${v.accentColor}" />
                    </div>
                </div>
                <div class="editor-prop-group">
                    <div style="font-size:11px;font-weight:700;color:var(--nsr-primary);">${t('editor.veh_modules_title')}</div>
                    ${modsHtml}
                </div>
            `;
            bindVehicleInspectorEvents(container);
        } else if (activeTab === 'themes') {
            const themeKeys = ['midnight', 'neon', 'minimal', 'sport', 'luxury', 'tactical'];
            const themeOpts = themeKeys.map((tk) => `
                <option value="${tk}" ${workingProfile.theme === tk ? 'selected' : ''}>${t('theme.' + tk)}</option>
            `).join('');

            container.innerHTML = `
                <div class="editor-prop-group">
                    <div class="editor-prop-row">
                        <label>${t('editor.global_theme')}</label>
                        <select id="ed-g-theme" class="editor-select">${themeOpts}</select>
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.global_cinematic')}</label>
                        <input type="checkbox" id="ed-g-cinematic" ${workingProfile.cinematicMode ? 'checked' : ''} />
                    </div>
                    <div class="editor-prop-row">
                        <label>${t('editor.global_grid')}</label>
                        <input type="checkbox" id="ed-g-grid" ${showGrid ? 'checked' : ''} />
                    </div>
                </div>
            `;
            bindThemeInspectorEvents(container);
        } else if (activeTab === 'presets') {
            const presets = workingProfile.presets || [];
            const listHtml = presets.length === 0
                ? `<div style="font-size:12px;color:var(--nsr-text-muted);">${t('editor.preset_empty')}</div>`
                : presets.map((p, idx) => `
                    <div class="editor-prop-row">
                        <strong>${p.name}</strong>
                        <div style="display:flex;gap:6px;">
                            <button type="button" class="btn-editor btn-secondary" data-load-preset="${idx}">${t('editor.preset_load')}</button>
                            <button type="button" class="btn-editor btn-danger" data-del-preset="${idx}">${t('editor.preset_delete')}</button>
                        </div>
                    </div>
                `).join('');

            container.innerHTML = `
                <div class="editor-prop-group">
                    <label style="font-size:12px;font-weight:700;">${t('editor.preset_name_label')}</label>
                    <div class="cp-input-row">
                        <input type="text" id="ed-preset-name" class="cp-input" maxlength="24" placeholder="${t('editor.preset_name_placeholder')}" />
                        <button type="button" id="ed-save-preset-btn" class="btn-editor btn-primary">${t('editor.preset_save_btn')}</button>
                    </div>
                </div>
                <div class="editor-prop-group">
                    ${listHtml}
                </div>
            `;
            bindPresetInspectorEvents(container);
        }
    }

    function updateInspectorSliderValuesLive() {
        if (!workingProfile) return;
        if (activeTab === 'widgets') {
            const w = workingProfile.widgets[selectedWidgetId];
            if (!w) return;
            const xIn = document.getElementById('ed-w-x');
            const yIn = document.getElementById('ed-w-y');
            const xVal = document.getElementById('ed-w-x-val');
            const yVal = document.getElementById('ed-w-y-val');
            if (xIn) xIn.value = String(w.x);
            if (yIn) yIn.value = String(w.y);
            if (xVal) xVal.textContent = `(${w.x}%)`;
            if (yVal) yVal.textContent = `(${w.y}%)`;
        } else if (activeTab === 'vehicle') {
            const v = workingProfile.vehicle;
            const xIn = document.getElementById('ed-v-x');
            const yIn = document.getElementById('ed-v-y');
            const xVal = document.getElementById('ed-v-x-val');
            const yVal = document.getElementById('ed-v-y-val');
            if (xIn) xIn.value = String(v.x);
            if (yIn) yIn.value = String(v.y);
            if (xVal) xVal.textContent = `(${v.x}%)`;
            if (yVal) yVal.textContent = `(${v.y}%)`;
        }
    }

    function bindWidgetInspectorEvents(container) {
        container.querySelectorAll('[data-select-widget]').forEach((chip) => {
            chip.addEventListener('click', () => {
                selectedWidgetId = chip.getAttribute('data-select-widget');
                highlightSelectedElement();
                renderTabBody();
            });
        });

        const w = workingProfile.widgets[selectedWidgetId];
        if (!w) return;

        const bindField = (selector, eventName, handler) => {
            const el = container.querySelector(selector);
            if (el) el.addEventListener(eventName, handler);
        };

        bindField('#ed-w-enabled', 'change', (e) => { w.enabled = e.target.checked; applyWorkingChangesLive(); });
        bindField('#ed-w-style', 'change', (e) => { w.style = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-w-x', 'input', (e) => {
            w.x = Number(e.target.value);
            w.customPos = true;
            const lbl = container.querySelector('#ed-w-x-val');
            if (lbl) lbl.textContent = `(${w.x}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-w-y', 'input', (e) => {
            w.y = Number(e.target.value);
            w.customPos = true;
            const lbl = container.querySelector('#ed-w-y-val');
            if (lbl) lbl.textContent = `(${w.y}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-w-scale', 'input', (e) => {
            w.scale = Number(e.target.value);
            const lbl = container.querySelector('#ed-w-scale-val');
            if (lbl) lbl.textContent = `(${w.scale}x)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-w-opacity', 'input', (e) => {
            w.opacity = Number(e.target.value);
            const lbl = container.querySelector('#ed-w-opacity-val');
            if (lbl) lbl.textContent = `(${Math.round(w.opacity * 100)}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-w-color', 'input', (e) => { w.color = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-w-icon', 'change', (e) => { w.showIcon = e.target.checked; applyWorkingChangesLive(); });
        bindField('#ed-w-label', 'change', (e) => { w.showLabel = e.target.checked; applyWorkingChangesLive(); });
        bindField('#ed-w-value', 'change', (e) => { w.showValue = e.target.checked; applyWorkingChangesLive(); });

        bindField('#ed-reset-single-widget', 'click', () => {
            if (defaultProfile && defaultProfile.widgets && defaultProfile.widgets[selectedWidgetId]) {
                workingProfile.widgets[selectedWidgetId] = window.NSRPersistenceUI.deepClone(defaultProfile.widgets[selectedWidgetId]);
                workingProfile.widgets[selectedWidgetId].customPos = false;
                applyWorkingChangesLive();
                renderTabBody();
            }
        });
    }

    function bindVehicleInspectorEvents(container) {
        const v = workingProfile.vehicle;
        const bindField = (selector, eventName, handler) => {
            const el = container.querySelector(selector);
            if (el) el.addEventListener(eventName, handler);
        };

        bindField('#ed-v-preview', 'change', (e) => {
            previewVehOnFoot = e.target.checked;
            window.NSRVehicleHudUI.setEditorPreview(previewVehOnFoot);
        });
        bindField('#ed-v-preset', 'change', (e) => { v.preset = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-v-unit', 'change', (e) => { v.speedUnit = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-v-x', 'input', (e) => {
            v.x = Number(e.target.value);
            const lbl = container.querySelector('#ed-v-x-val');
            if (lbl) lbl.textContent = `(${v.x}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-v-y', 'input', (e) => {
            v.y = Number(e.target.value);
            const lbl = container.querySelector('#ed-v-y-val');
            if (lbl) lbl.textContent = `(${v.y}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-v-scale', 'input', (e) => {
            v.scale = Number(e.target.value);
            const lbl = container.querySelector('#ed-v-scale-val');
            if (lbl) lbl.textContent = `(${v.scale}x)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-v-opacity', 'input', (e) => {
            v.opacity = Number(e.target.value);
            const lbl = container.querySelector('#ed-v-opacity-val');
            if (lbl) lbl.textContent = `(${Math.round(v.opacity * 100)}%)`;
            applyWorkingChangesLive();
        });
        bindField('#ed-v-c1', 'input', (e) => { v.primaryColor = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-v-c2', 'input', (e) => { v.secondaryColor = e.target.value; applyWorkingChangesLive(); });
        bindField('#ed-v-c3', 'input', (e) => { v.accentColor = e.target.value; applyWorkingChangesLive(); });

        container.querySelectorAll('[data-veh-mod]').forEach((cb) => {
            cb.addEventListener('change', (e) => {
                const key = cb.getAttribute('data-veh-mod');
                v.modules[key] = e.target.checked;
                applyWorkingChangesLive();
            });
        });
    }

    function bindThemeInspectorEvents(container) {
        const thSelect = container.querySelector('#ed-g-theme');
        if (thSelect) {
            thSelect.addEventListener('change', (e) => {
                workingProfile.theme = e.target.value;
                applyWorkingChangesLive();
            });
        }
        const cinCheck = container.querySelector('#ed-g-cinematic');
        if (cinCheck) {
            cinCheck.addEventListener('change', (e) => {
                workingProfile.cinematicMode = e.target.checked;
                applyWorkingChangesLive();
            });
        }
        const gridCheck = container.querySelector('#ed-g-grid');
        if (gridCheck) {
            gridCheck.addEventListener('change', (e) => {
                showGrid = e.target.checked;
                window.NSRSettingsUI.applyGridOverlay(showGrid);
            });
        }
    }

    function bindPresetInspectorEvents(container) {
        const savePresetBtn = container.querySelector('#ed-save-preset-btn');
        if (savePresetBtn) {
            savePresetBtn.addEventListener('click', () => {
                const nameInput = container.querySelector('#ed-preset-name');
                const rawName = (nameInput ? nameInput.value : '').trim();
                if (!rawName) return;
                workingProfile.presets = workingProfile.presets || [];
                if (workingProfile.presets.length >= 5) {
                    window.NSRPersistenceUI.postNUI('editorNotify', { type: 'warning', key: 'notify.preset_limit' });
                    return;
                }
                workingProfile.presets.push({
                    id: 'preset_' + Date.now(),
                    name: rawName.slice(0, 24),
                    theme: workingProfile.theme,
                    widgets: window.NSRPersistenceUI.deepClone(workingProfile.widgets)
                });
                window.NSRPersistenceUI.postNUI('editorNotify', { type: 'success', key: 'notify.preset_saved', params: { name: rawName } });
                renderTabBody();
            });
        }

        container.querySelectorAll('[data-load-preset]').forEach((btn) => {
            btn.addEventListener('click', () => {
                const idx = Number(btn.getAttribute('data-load-preset'));
                const p = workingProfile.presets && workingProfile.presets[idx];
                if (p) {
                    workingProfile.theme = p.theme || workingProfile.theme;
                    workingProfile.widgets = window.NSRPersistenceUI.deepClone(p.widgets);
                    applyWorkingChangesLive();
                    window.NSRPersistenceUI.postNUI('editorNotify', { type: 'info', key: 'notify.preset_loaded', params: { name: p.name } });
                }
            });
        });

        container.querySelectorAll('[data-del-preset]').forEach((btn) => {
            btn.addEventListener('click', () => {
                const idx = Number(btn.getAttribute('data-del-preset'));
                if (workingProfile.presets && workingProfile.presets[idx]) {
                    workingProfile.presets.splice(idx, 1);
                    window.NSRPersistenceUI.postNUI('editorNotify', { type: 'info', key: 'notify.preset_deleted' });
                    renderTabBody();
                }
            });
        });
    }

    function setupCanvasAndPanelDragging() {
        window.addEventListener('mousedown', (e) => {
            if (!isOpen) return;

            // 1. Check if user is dragging the Editor Studio Window header itself
            const headerEl = e.target.closest('#editor-drag-header');
            const closeBtnEl = e.target.closest('#editor-close-top');
            if (headerEl && !closeBtnEl) {
                const panel = document.getElementById('editor-panel');
                if (panel) {
                    const rect = panel.getBoundingClientRect();
                    dragState = {
                        type: 'editor_panel',
                        startX: e.clientX,
                        startY: e.clientY,
                        origLeft: rect.left,
                        origTop: rect.top
                    };
                    e.preventDefault();
                    return;
                }
            }

            // Ignore clicks inside the rest of the editor panel or confirm dialog
            if (e.target.closest('#editor-panel') || e.target.closest('#editor-confirm-modal')) {
                return;
            }

            // 2. Check if user clicked a Player HUD widget or the Vehicle HUD on the canvas
            const widgetEl = e.target.closest('.hud-widget');
            const vehEl = e.target.closest('#vehicle-hud-wrapper');
            const panel = document.getElementById('editor-panel');

            if (widgetEl) {
                const wId = widgetEl.dataset.widgetId;
                selectedWidgetId = wId;
                const wCfg = workingProfile.widgets[wId];
                const currentLeftPct = parseFloat(widgetEl.style.left);
                const currentTopPct = parseFloat(widgetEl.style.top);
                wCfg.x = Number.isFinite(currentLeftPct) ? currentLeftPct : wCfg.x;
                wCfg.y = Number.isFinite(currentTopPct) ? currentTopPct : wCfg.y;

                dragState = {
                    type: 'widget',
                    id: wId,
                    startX: e.clientX,
                    startY: e.clientY,
                    origX: wCfg.x,
                    origY: wCfg.y
                };
                if (panel) panel.classList.add('dragging-canvas-item');
                if (activeTab !== 'widgets') {
                    switchTab('widgets');
                } else {
                    highlightSelectedElement();
                    renderTabBody();
                }
                e.preventDefault();
            } else if (vehEl) {
                const vCfg = workingProfile.vehicle;
                dragState = {
                    type: 'vehicle',
                    startX: e.clientX,
                    startY: e.clientY,
                    origX: vCfg.x,
                    origY: vCfg.y
                };
                if (panel) panel.classList.add('dragging-canvas-item');
                if (activeTab !== 'vehicle') {
                    switchTab('vehicle');
                } else {
                    highlightSelectedElement();
                }
                e.preventDefault();
            }
        });

        window.addEventListener('mousemove', (e) => {
            if (!isOpen || !dragState) return;

            // Dragging the Studio Editor Window itself
            if (dragState.type === 'editor_panel') {
                const panel = document.getElementById('editor-panel');
                if (!panel) return;
                const dx = e.clientX - dragState.startX;
                const dy = e.clientY - dragState.startY;
                const maxLeft = Math.max(0, window.innerWidth - panel.offsetWidth);
                const maxTop = Math.max(0, window.innerHeight - 60);
                const nextLeft = window.NSRPersistenceUI.clamp(dragState.origLeft + dx, 0, maxLeft);
                const nextTop = window.NSRPersistenceUI.clamp(dragState.origTop + dy, 0, maxTop);
                panel.style.left = `${Math.round(nextLeft)}px`;
                panel.style.top = `${Math.round(nextTop)}px`;
                panel.style.right = 'auto';
                return;
            }

            if (!workingProfile) return;
            const dxPct = ((e.clientX - dragState.startX) / window.innerWidth) * 100;
            const dyPct = ((e.clientY - dragState.startY) / window.innerHeight) * 100;

            let newX = window.NSRPersistenceUI.clamp(dragState.origX + dxPct, 0.0, 96.0);
            let newY = window.NSRPersistenceUI.clamp(dragState.origY + dyPct, 0.0, 96.0);

            const snapX = document.getElementById('snap-line-x');
            const snapY = document.getElementById('snap-line-y');
            if (Math.abs(newX - 50.0) < 0.8) {
                newX = 50.0;
                if (snapX) snapX.classList.remove('hidden');
            } else if (snapX) {
                snapX.classList.add('hidden');
            }

            if (Math.abs(newY - 50.0) < 0.8) {
                newY = 50.0;
                if (snapY) snapY.classList.remove('hidden');
            } else if (snapY) {
                snapY.classList.add('hidden');
            }

            newX = Number(newX.toFixed(1));
            newY = Number(newY.toFixed(1));

            if (dragState.type === 'widget') {
                const w = workingProfile.widgets[dragState.id];
                w.x = newX;
                w.y = newY;
                w.customPos = true;
            } else if (dragState.type === 'vehicle') {
                workingProfile.vehicle.x = window.NSRPersistenceUI.clamp(newX, 0.0, 95.0);
                workingProfile.vehicle.y = window.NSRPersistenceUI.clamp(newY, 0.0, 95.0);
            }

            applyWorkingChangesLive();
            updateInspectorSliderValuesLive();
        });

        window.addEventListener('mouseup', () => {
            if (!dragState) return;
            dragState = null;
            const panel = document.getElementById('editor-panel');
            if (panel) panel.classList.remove('dragging-canvas-item');
            const snapX = document.getElementById('snap-line-x');
            const snapY = document.getElementById('snap-line-y');
            if (snapX) snapX.classList.add('hidden');
            if (snapY) snapY.classList.add('hidden');
        });
    }

    function bindStaticStudioControls() {
        document.querySelectorAll('.editor-tab-btn').forEach((btn) => {
            btn.addEventListener('click', () => switchTab(btn.getAttribute('data-tab')));
        });

        const saveBtn = document.getElementById('editor-save-btn');
        if (saveBtn) {
            saveBtn.addEventListener('click', async () => {
                if (!workingProfile) return;
                window.NSRMainUI.setProfile(workingProfile);
                await window.NSRPersistenceUI.postNUI('saveProfile', workingProfile);
                close();
            });
        }

        const cancelAction = async () => {
            await window.NSRPersistenceUI.postNUI('cancelEditor', {});
            close();
        };

        const cancelBtn = document.getElementById('editor-cancel-btn');
        const closeTopBtn = document.getElementById('editor-close-top');
        if (cancelBtn) cancelBtn.addEventListener('click', cancelAction);
        if (closeTopBtn) closeTopBtn.addEventListener('click', cancelAction);

        const resetAllBtn = document.getElementById('editor-reset-all-btn');
        const confirmModal = document.getElementById('editor-confirm-modal');
        const confirmCancel = document.getElementById('confirm-reset-cancel');
        const confirmYes = document.getElementById('confirm-reset-yes');

        if (resetAllBtn && confirmModal) {
            resetAllBtn.addEventListener('click', () => confirmModal.classList.remove('hidden'));
        }
        if (confirmCancel && confirmModal) {
            confirmCancel.addEventListener('click', () => confirmModal.classList.add('hidden'));
        }
        if (confirmYes && confirmModal) {
            confirmYes.addEventListener('click', async () => {
                confirmModal.classList.add('hidden');
                const res = await window.NSRPersistenceUI.postNUI('resetProfile', {});
                if (res && res.profile) {
                    workingProfile = window.NSRPersistenceUI.sanitizeProfile(res.profile, defaultProfile);
                } else if (defaultProfile) {
                    workingProfile = window.NSRPersistenceUI.deepClone(defaultProfile);
                }
                applyWorkingChangesLive();
                renderTabBody();
            });
        }

        setupCanvasAndPanelDragging();
    }

    document.addEventListener('DOMContentLoaded', bindStaticStudioControls);

    window.NSREditorUI = {
        setDefaultProfile: setDefaultProfile,
        open: open,
        close: close,
        isOpen: function () { return isOpen; }
    };
})(window);
