/* ============================================================================
   NSR HUD ULTIMATE — PLAYER HUD RENDERER (html/js/player-hud.js)
   Guarantees bottom-left status widgets ALWAYS pack side-by-side with zero gaps
   when any status icon (like Armor, Stamina, Oxygen, Stress) is hidden,
   while preserving custom user-dragged positions (`customPos = true`).
   ============================================================================ */

(function (window) {
    'use strict';

    const WIDGET_META = {
        health:   { icon: 'health.svg',   labelKey: 'hud.health',   isStatusRow: true  },
        armor:    { icon: 'armor.svg',    labelKey: 'hud.armor',    isStatusRow: true  },
        hunger:   { icon: 'hunger.svg',   labelKey: 'hud.hunger',   isStatusRow: true  },
        thirst:   { icon: 'thirst.svg',   labelKey: 'hud.thirst',   isStatusRow: true  },
        stamina:  { icon: 'stamina.svg',  labelKey: 'hud.stamina',  isStatusRow: true  },
        oxygen:   { icon: 'oxygen.svg',   labelKey: 'hud.oxygen',   isStatusRow: true  },
        stress:   { icon: 'stress.svg',   labelKey: 'hud.stress',   isStatusRow: true  },
        voice:    { icon: 'voice.svg',    labelKey: 'hud.voice',    isStatusRow: true  },
        playerid: { icon: 'compass.svg',  labelKey: 'hud.playerid', isStatusRow: false },
        cash:     { icon: 'cash.svg',     labelKey: 'hud.cash',     isStatusRow: false },
        bank:     { icon: 'bank.svg',     labelKey: 'hud.bank',     isStatusRow: false },
        job:      { icon: 'job.svg',      labelKey: 'hud.job',      isStatusRow: false },
        compass:  { icon: 'compass.svg',  labelKey: 'hud.compass',  isStatusRow: false },
        location: { icon: 'compass.svg',  labelKey: 'hud.location', isStatusRow: false },
        clock:    { icon: 'compass.svg',  labelKey: 'hud.clock',    isStatusRow: false }
    };

    const STATUS_ROW_ORDER = ['health', 'armor', 'hunger', 'thirst', 'stamina', 'oxygen', 'stress', 'voice'];
    const RING_CIRCUMFERENCE = 2 * Math.PI * 19;
    const domNodes = {};
    let currentLayout = {};
    let lastTelemetry = {};
    let editorMode = false;

    function buildWidgetStructure(widgetId, style) {
        const meta = WIDGET_META[widgetId] || { icon: 'health.svg', labelKey: 'hud.' + widgetId };
        const iconUrl = `assets/icons/${meta.icon}`;
        const labelText = window.NSRLocaleUI.t(meta.labelKey);

        if (style === 'ring') {
            return `
                <svg class="hud-ring-svg" viewBox="0 0 46 46">
                    <circle class="hud-ring-track" cx="23" cy="23" r="19"></circle>
                    <circle class="hud-ring-fill" cx="23" cy="23" r="19"
                        stroke-dasharray="${RING_CIRCUMFERENCE.toFixed(2)}"
                        stroke-dashoffset="0"></circle>
                </svg>
                <div class="hud-ring-center">
                    <span class="hud-widget-icon" style="-webkit-mask-image: url('${iconUrl}'); mask-image: url('${iconUrl}');"></span>
                    <span class="hud-widget-val">100%</span>
                    <span class="hud-widget-lbl">${labelText}</span>
                </div>
            `;
        }

        if (style === 'bar') {
            return `
                <div class="hud-bar-header">
                    <div class="hud-bar-left">
                        <span class="hud-widget-icon" style="-webkit-mask-image: url('${iconUrl}'); mask-image: url('${iconUrl}');"></span>
                        <span class="hud-widget-lbl">${labelText}</span>
                    </div>
                    <span class="hud-widget-val">100%</span>
                </div>
                <div class="hud-bar-track">
                    <div class="hud-bar-fill" style="width: 100%;"></div>
                </div>
            `;
        }

        return `
            <span class="hud-widget-icon" style="-webkit-mask-image: url('${iconUrl}'); mask-image: url('${iconUrl}');"></span>
            <span class="hud-widget-lbl">${labelText}</span>
            <span class="hud-widget-val">100</span>
        `;
    }

    function ensureWidgetsCreated() {
        const container = document.getElementById('player-hud-layer');
        if (!container) return;

        window.NSRPersistenceUI.WIDGET_IDS.forEach((id) => {
            if (!domNodes[id]) {
                const el = document.createElement('div');
                el.className = 'hud-widget style-ring';
                el.dataset.widgetId = id;
                el.dataset.style = 'ring';
                el.innerHTML = buildWidgetStructure(id, 'ring');
                container.appendChild(el);
                domNodes[id] = el;
            }
        });
    }

    function applyLayout(widgetsConfig) {
        ensureWidgetsCreated();
        if (!widgetsConfig || typeof widgetsConfig !== 'object') return;
        currentLayout = widgetsConfig;

        window.NSRPersistenceUI.WIDGET_IDS.forEach((id) => {
            const cfg = widgetsConfig[id];
            const el = domNodes[id];
            if (!cfg || !el) return;

            if (el.dataset.style !== cfg.style) {
                el.dataset.style = cfg.style;
                el.className = `hud-widget style-${cfg.style}`;
                el.innerHTML = buildWidgetStructure(id, cfg.style);
            }

            el.style.left = `${cfg.x}%`;
            el.style.top = `${cfg.y}%`;
            el.style.opacity = String(cfg.opacity);
            el.style.setProperty('--widget-color', cfg.color);
            el.style.setProperty('--widget-scale', String(cfg.scale));
            el.style.transform = `scale(${cfg.scale})`;

            const iconEl = el.querySelector('.hud-widget-icon');
            const lblEl = el.querySelector('.hud-widget-lbl');
            const valEl = el.querySelector('.hud-widget-val');

            if (iconEl) iconEl.classList.toggle('hidden', !cfg.showIcon);
            if (lblEl) {
                const showLbl = Boolean(cfg.showLabel) && cfg.style !== 'ring';
                lblEl.classList.toggle('hidden', !showLbl);
                lblEl.textContent = window.NSRLocaleUI.t(WIDGET_META[id].labelKey);
            }
            if (valEl) valEl.classList.toggle('hidden', !cfg.showValue);
        });

        updateData(lastTelemetry);
    }

    function computeWidgetDisplay(id, data) {
        const t = window.NSRLocaleUI.t;
        const cfg = currentLayout[id] || {};
        switch (id) {
            case 'health': {
                const pct = data.health !== undefined ? data.health : 100;
                const valText = data.isDead ? t('hud.dead_status') : `${pct}%`;
                return { available: true, percent: pct, text: valText, critical: pct <= 25 || data.isDead };
            }
            case 'armor': {
                const pct = data.armor !== undefined ? data.armor : 0;
                const autoHide = !editorMode && pct <= 0;
                return { available: !autoHide, percent: pct, text: `${pct}%` };
            }
            case 'hunger': {
                if (!editorMode && data.hungerAvailable === false) return { available: false };
                const pct = data.hunger !== undefined && data.hunger !== null ? data.hunger : 100;
                return { available: true, percent: pct, text: `${pct}%`, critical: pct <= 15 };
            }
            case 'thirst': {
                if (!editorMode && data.thirstAvailable === false) return { available: false };
                const pct = data.thirst !== undefined && data.thirst !== null ? data.thirst : 100;
                return { available: true, percent: pct, text: `${pct}%`, critical: pct <= 15 };
            }
            case 'stamina': {
                const pct = data.stamina !== undefined ? data.stamina : 100;
                const autoHide = !editorMode && pct >= 99;
                return { available: !autoHide, percent: pct, text: `${pct}%` };
            }
            case 'oxygen': {
                const pct = data.oxygen !== undefined ? data.oxygen : 100;
                const autoHide = !editorMode && !data.isUnderwater && pct >= 99;
                return { available: !autoHide, percent: pct, text: `${pct}%`, critical: pct <= 25 };
            }
            case 'stress': {
                if (!editorMode && !data.stressAvailable) return { available: false };
                const pct = data.stress || 0;
                return { available: true, percent: pct, text: `${pct}%`, critical: pct >= 80 };
            }
            case 'voice': {
                const v = data.voice || { value: 66, talking: false, radioActive: false, label: t('hud.voice_normal') };
                const pct = v.value || 66;
                let valStr = `${pct}%`;
                if (v.radioActive || (v.radioChannel && v.radioChannel > 0)) {
                    valStr = `CH${v.radioChannel}`;
                } else if (cfg.style !== 'ring') {
                    valStr = v.label || t('hud.voice_normal');
                }
                return {
                    available: true,
                    percent: pct,
                    text: valStr,
                    talking: Boolean(v.talking || v.radioActive)
                };
            }
            case 'playerid': {
                const sid = data.serverId !== undefined ? data.serverId : 1;
                return { available: true, percent: 100, text: `#${sid}` };
            }
            case 'cash': {
                if (!editorMode && data.cashAvailable === false) return { available: false };
                const formatted = window.NSRLocaleUI.formatCurrency(data.cash || 0, data.currencySymbol, data.currencyPosition);
                return { available: true, percent: 100, text: formatted };
            }
            case 'bank': {
                if (!editorMode && data.bankAvailable === false) return { available: false };
                const formatted = window.NSRLocaleUI.formatCurrency(data.bank || 0, data.currencySymbol, data.currencyPosition);
                return { available: true, percent: 100, text: formatted };
            }
            case 'job': {
                if (!editorMode && data.jobAvailable === false) return { available: false };
                const jobStr = data.jobLabel
                    ? (data.gradeLabel ? `${data.jobLabel} • ${data.gradeLabel}` : data.jobLabel)
                    : t('hud.unemployed');
                return { available: true, percent: 100, text: jobStr };
            }
            case 'compass': {
                const card = data.cardinal || t('compass.N');
                const deg = data.heading !== undefined ? data.heading : 0;
                return { available: true, percent: 100, text: `${card} ${deg}°` };
            }
            case 'location': {
                const street = data.street || 'Legion Square';
                const zone = data.zone ? ` (${data.zone})` : '';
                return { available: true, percent: 100, text: street + zone };
            }
            case 'clock': {
                return { available: true, percent: 100, text: data.clock || '12:00' };
            }
            default:
                return { available: false };
        }
    }

    function updateData(telemetry) {
        ensureWidgetsCreated();
        if (telemetry && typeof telemetry === 'object') {
            lastTelemetry = telemetry;
        }

        const radarVisible = lastTelemetry.radarVisible !== false;
        const autoCompact = lastTelemetry.autoCompact !== false && !editorMode;
        const baseStartX = radarVisible ? 16.2 : 1.6;
        const stepX = 3.15;
        let visibleStatusSlot = 0;

        window.NSRPersistenceUI.WIDGET_IDS.forEach((id) => {
            const el = domNodes[id];
            const cfg = currentLayout[id];
            if (!el || !cfg) return;

            if (!cfg.enabled) {
                el.classList.add('hidden');
                return;
            }

            const disp = computeWidgetDisplay(id, lastTelemetry);
            if (!disp.available) {
                el.classList.add('hidden');
                return;
            }

            el.classList.remove('hidden');
            el.classList.toggle('voice-talking', Boolean(disp.talking));
            el.classList.toggle('critical-pulse', Boolean(disp.critical));

            const isStatusWidget = STATUS_ROW_ORDER.includes(id);
            if (autoCompact && isStatusWidget && !cfg.customPos) {
                // Pack all visible bottom-left status icons tightly side-by-side with zero gaps!
                const dockY = (currentLayout.health && Number(currentLayout.health.y)) || 92.0;
                const computedX = baseStartX + (visibleStatusSlot * stepX * (Number(cfg.scale) || 1.0));
                el.style.left = `${computedX.toFixed(2)}%`;
                el.style.top = `${dockY.toFixed(2)}%`;
                visibleStatusSlot += 1;
            } else {
                el.style.left = `${cfg.x}%`;
                el.style.top = `${cfg.y}%`;
            }

            const valEl = el.querySelector('.hud-widget-val');
            if (valEl) {
                valEl.textContent = disp.text;
            }

            const pct = window.NSRPersistenceUI.clamp(disp.percent !== undefined ? disp.percent : 100, 0, 100);
            const ringFill = el.querySelector('.hud-ring-fill');
            if (ringFill) {
                const offset = RING_CIRCUMFERENCE - (pct / 100) * RING_CIRCUMFERENCE;
                ringFill.style.strokeDashoffset = offset.toFixed(2);
            }

            const barFill = el.querySelector('.hud-bar-fill');
            if (barFill) {
                barFill.style.width = `${pct}%`;
            }
        });
    }

    function setEditorMode(enabled) {
        editorMode = Boolean(enabled);
        updateData(lastTelemetry);
    }

    window.NSRPlayerHudUI = {
        applyLayout: applyLayout,
        updateData: updateData,
        setEditorMode: setEditorMode,
        getWidgetMeta: function () { return WIDGET_META; }
    };
})(window);
