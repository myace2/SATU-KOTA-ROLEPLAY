/* ============================================================================
   NSR HUD ULTIMATE — 6 DYNAMIC FRAMELESS CARHUD STYLES (html/js/vehicle-hud.js)
   Matches reference designs (`modern`, `aggressive`, `circle`, `simple_racing`,
   `simple`, `sport`, plus frameless `nfs_heat`) with automatic Aircraft &
   Watercraft Modes and zero rectangular blue background box.
   ============================================================================ */

(function (window) {
    'use strict';

    let currentConfig = null;
    let lastVehicleData = { inVehicle: false };
    let previewInEditor = false;
    let builtKey = null;

    // Normalize any legacy preset names to our 7 supported styles
    function resolveStyleName(rawPreset) {
        const map = {
            aggressive: 'aggressive',
            modern: 'modern',
            circle: 'circle',
            simple_racing: 'simple_racing',
            simple: 'simple',
            sport: 'sport',
            nfs_heat: 'nfs_heat',
            nfs_unbound: 'simple_racing',
            nfs_mostwanted: 'modern',
            cyber_digital: 'aggressive',
            analog_classic: 'modern',
            sport_gt: 'sport',
            minimal_strip: 'simple'
        };
        return map[rawPreset] || 'aggressive';
    }

    function polar(cx, cy, r, deg) {
        const rad = (deg * Math.PI) / 180;
        return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
    }

    function describeArc(cx, cy, r, startDeg, endDeg) {
        const start = polar(cx, cy, r, endDeg);
        const end = polar(cx, cy, r, startDeg);
        const largeArc = (endDeg - startDeg) <= 180 ? '0' : '1';
        return `M ${start.x.toFixed(2)} ${start.y.toFixed(2)} A ${r} ${r} 0 ${largeArc} 0 ${end.x.toFixed(2)} ${end.y.toFixed(2)}`;
    }

    function buildTelltalesHtml() {
        return `
            <span id="veh-tt-seatbelt" class="ch-telltale">
                <span class="ch-icon" style="-webkit-mask-image:url('assets/icons/seatbelt.svg');mask-image:url('assets/icons/seatbelt.svg');"></span>
            </span>
            <span id="veh-tt-engine" class="ch-telltale">
                <span class="ch-icon" style="-webkit-mask-image:url('assets/icons/engine.svg');mask-image:url('assets/icons/engine.svg');"></span>
            </span>
            <span id="veh-tt-lights" class="ch-telltale">
                <span class="ch-icon" style="-webkit-mask-image:url('assets/icons/lights.svg');mask-image:url('assets/icons/lights.svg');"></span>
            </span>
            <span id="veh-tt-lock" class="ch-telltale">
                <span class="ch-icon" style="-webkit-mask-image:url('assets/icons/lock.svg');mask-image:url('assets/icons/lock.svg');"></span>
            </span>
        `;
    }

    // Special Aircraft / Watercraft circular mode (matches middle columns of image_cd4d9d.png)
    function buildSpecialCraftTemplate(category, t) {
        const isAir = (category === 'helicopter' || category === 'airplane');
        const mainArcPath = describeArc(105, 105, 82, 135, 345);
        const fuelArcPath = describeArc(105, 105, 82, 352, 405);
        const modeCaption = isAir ? '✈ [Aircraft Mode]' : '⛴ [Watercraft Mode]';

        return `
            <div class="ch-dial-wrap">
                <div class="ch-dial-lens"></div>
                <svg class="ch-dial-svg" viewBox="0 0 210 210">
                    <path d="${mainArcPath}" fill="none" stroke="rgba(255,255,255,0.16)" stroke-width="5" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="${mainArcPath}" fill="none" stroke="#84CC16" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="300" stroke-dashoffset="120"/>
                    <path d="${fuelArcPath}" fill="none" stroke="rgba(255,255,255,0.14)" stroke-width="5" stroke-linecap="round"/>
                    <path id="veh-arc-fuel" d="${fuelArcPath}" fill="none" stroke="#4ADE80" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="78" stroke-dashoffset="15"/>
                    ${isAir
                        ? `<line x1="42" y1="105" x2="168" y2="122" stroke="#EF4444" stroke-width="1.8" stroke-opacity="0.85"/>`
                        : `<polygon points="105,96 86,52 124,52" fill="rgba(16, 185, 129, 0.28)"/>
                           <polygon points="105,96 98,72 112,72" fill="#10B981"/>`
                    }
                </svg>
                <div class="ch-dial-center">
                    <div id="veh-speed-val" class="ch-speed-big">${isAir ? '180' : '150'}</div>
                    <div id="veh-speed-unit" class="ch-unit-sub">${isAir ? 'AIRSPEED' : t('vehicle.speed_knots')}</div>
                    ${isAir ? `<div style="font-size:10px;color:#94A3B8;margin-top:6px;"><span id="veh-altitude-val">0</span> FT</div>` : ''}
                    <div class="ch-bottom-icons">${buildTelltalesHtml()}</div>
                </div>
                <div class="ch-corner-fuel-badge">
                    <span class="ch-icon" style="width:11px;height:11px;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                    <span id="veh-fuel-text">75L</span>
                </div>
            </div>
            <div class="ch-mode-caption">${modeCaption}</div>
        `;
    }

    // 1. AGGRESSIVE STYLE (Middle-Right of image_cd4d9d.png)
    function buildAggressiveTemplate(t) {
        const whiteArc = describeArc(105, 105, 84, 140, 330);
        const redArc = describeArc(105, 105, 84, 332, 400);
        const nums = [1, 2, 3, 4, 5, 6].map((n, idx) => {
            const deg = 152 + idx * 45;
            const pt = polar(105, 105, 68, deg);
            const color = n >= 5 ? '#EF4444' : '#E2E8F0';
            return `<text x="${pt.x.toFixed(1)}" y="${pt.y.toFixed(1)}" fill="${color}" font-family="Segoe UI, sans-serif" font-weight="800" font-size="13" text-anchor="middle" dominant-baseline="central">${n}</text>`;
        }).join('');

        return `
            <div class="ch-dial-wrap">
                <div class="ch-dial-lens"></div>
                <svg class="ch-dial-svg" viewBox="0 0 210 210">
                    <path d="${whiteArc}" fill="none" stroke="rgba(255,255,255,0.20)" stroke-width="4.5" stroke-linecap="round"/>
                    <path d="${redArc}" fill="none" stroke="rgba(239,68,68,0.35)" stroke-width="4.5" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="${describeArc(105, 105, 84, 140, 400)}" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="382" stroke-dashoffset="382"/>
                    <g>${nums}</g>
                </svg>
                <div class="ch-dial-center">
                    <div id="veh-gear-strip" class="ch-gear-strip">
                        <span id="veh-gear-prev">1</span>
                        <span id="veh-gear-val" class="gear-active-pill">2</span>
                        <span id="veh-gear-next">3</span>
                    </div>
                    <div id="veh-speed-val" class="ch-speed-big italic-condensed">000</div>
                    <div id="veh-speed-unit" class="ch-unit-sub">${t('vehicle.speed_kmh')}</div>
                    <div class="ch-agg-fuel-row">
                        <span class="ch-icon" style="width:11px;height:11px;color:#84CC16;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                        <div class="ch-agg-fuel-track">
                            <div id="veh-fuel-bar" class="ch-agg-fuel-fill" style="width:75%;"></div>
                        </div>
                    </div>
                    <div class="ch-bottom-icons">${buildTelltalesHtml()}</div>
                </div>
            </div>
        `;
    }

    // 2. MODERN STYLE (Top-Left of image_cd4d9d.png)
    function buildModernTemplate(t) {
        const speedLabels = [20, 60, 100, 140, 180, 220, 260, 300].map((spd, idx) => {
            const deg = 145 + idx * 34;
            const pt = polar(105, 105, 67, deg);
            return `<text x="${pt.x.toFixed(1)}" y="${pt.y.toFixed(1)}" fill="rgba(255,255,255,0.65)" font-size="8.5" font-weight="700" text-anchor="middle" dominant-baseline="central">${spd}</text>`;
        }).join('');

        const mainArc = describeArc(105, 105, 84, 138, 345);
        const fuelArc = describeArc(105, 105, 84, 355, 405);

        return `
            <div class="ch-dial-wrap">
                <div class="ch-dial-lens"></div>
                <svg class="ch-dial-svg" viewBox="0 0 210 210">
                    <path d="${mainArc}" fill="none" stroke="rgba(255,255,255,0.16)" stroke-width="5" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="${mainArc}" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="304" stroke-dashoffset="304"/>
                    <path d="${fuelArc}" fill="none" stroke="rgba(255,255,255,0.14)" stroke-width="5" stroke-linecap="round"/>
                    <path id="veh-arc-fuel" d="${fuelArc}" fill="none" stroke="#84CC16" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="74" stroke-dashoffset="18"/>
                    <g>${speedLabels}</g>
                    <g id="veh-nfs-needle" style="transform-origin:105px 105px; transform:rotate(-120deg); transition:transform 0.06s linear;">
                        <line x1="105" y1="105" x2="105" y2="42" stroke="rgba(255,255,255,0.85)" stroke-width="2.4" stroke-linecap="round"/>
                        <circle cx="105" cy="105" r="4" fill="#FFFFFF"/>
                    </g>
                </svg>
                <div class="ch-dial-center" style="padding-top:10px;">
                    <div id="veh-speed-val" class="ch-speed-big">000</div>
                    <div id="veh-speed-unit" class="ch-unit-sub">${t('vehicle.speed_kmh')}</div>
                    <div class="ch-gear-strip" style="margin-top:4px;">
                        <span id="veh-gear-prev">N</span>
                        <span id="veh-gear-val" class="gear-active-red">1</span>
                        <span id="veh-gear-next">2</span>
                    </div>
                    <div class="ch-bottom-icons">${buildTelltalesHtml()}</div>
                </div>
                <div class="ch-corner-fuel-badge">
                    <span class="ch-icon" style="width:11px;height:11px;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                    <span id="veh-fuel-text">75L</span>
                </div>
            </div>
        `;
    }

    // 3. CIRCLE STYLE (Bottom-Left of image_cd4d9d.png)
    function buildCircleTemplate(t) {
        const outerArc = describeArc(105, 105, 84, 135, 405);
        const fuelArc = describeArc(105, 105, 75, 345, 405);
        return `
            <div class="ch-dial-wrap">
                <div class="ch-dial-lens"></div>
                <svg class="ch-dial-svg" viewBox="0 0 210 210">
                    <path d="${outerArc}" fill="none" stroke="rgba(255,255,255,0.15)" stroke-width="6.5" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="${outerArc}" fill="none" stroke="#FFFFFF" stroke-width="6.5" stroke-linecap="round"
                        stroke-dasharray="395" stroke-dashoffset="395"/>
                    <path d="${fuelArc}" fill="none" stroke="rgba(255,255,255,0.12)" stroke-width="4.5" stroke-linecap="round"/>
                    <path id="veh-arc-fuel" d="${fuelArc}" fill="none" stroke="#84CC16" stroke-width="4.5" stroke-linecap="round"
                        stroke-dasharray="78" stroke-dashoffset="20"/>
                </svg>
                <div class="ch-dial-center">
                    <div class="ch-gear-strip" style="margin-bottom:6px;">
                        <span id="veh-gear-prev">N</span>
                        <span id="veh-gear-val" class="gear-active-red">1</span>
                        <span id="veh-gear-next">2</span>
                    </div>
                    <div id="veh-speed-val" class="ch-speed-big">000</div>
                    <div id="veh-speed-unit" class="ch-unit-sub">${t('vehicle.speed_kmh')}</div>
                    <div class="ch-bottom-icons" style="margin-top:10px;">
                        ${buildTelltalesHtml()}
                        <span style="display:inline-flex;align-items:center;gap:3px;font-size:10px;font-weight:800;color:#84CC16;">
                            <span class="ch-icon" style="width:11px;height:11px;color:#84CC16;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                            <span id="veh-fuel-text">75L</span>
                        </span>
                    </div>
                </div>
            </div>
        `;
    }

    // 4. SIMPLE RACING STYLE (Top-Right of image_cd4dbb.png — Frameless!)
    function buildSimpleRacingTemplate(t) {
        const bars = Array.from({ length: 12 }, (_, i) => {
            const red = i >= 8 ? 'red-zone' : '';
            return `<div class="ch-sr-seg ${red}" data-seg="${i}"></div>`;
        }).join('');

        return `
            <div class="ch-simple-racing">
                <div class="ch-sr-top">
                    <span id="veh-speed-val" class="ch-sr-speed">000</span>
                    <span id="veh-speed-unit" class="ch-sr-unit">${t('vehicle.speed_kmh')}</span>
                    <span id="veh-gear-val" class="ch-sr-unit" style="color:#EF4444;margin-left:6px;font-size:15px;font-style:italic;">N</span>
                </div>
                <div class="ch-sr-bottom">
                    <div id="veh-rpm-strip" class="ch-sr-bars">${bars}</div>
                    <div class="ch-sr-icons-col">
                        ${buildTelltalesHtml()}
                    </div>
                </div>
            </div>
        `;
    }

    // 5. SIMPLE STYLE (Middle-Left of image_cd4dbb.png — Frameless!)
    function buildSimpleCleanTemplate(t) {
        return `
            <div class="ch-simple-clean">
                <div class="ch-sc-top">
                    <span id="veh-speed-val" class="ch-sc-speed">000</span>
                    <span id="veh-speed-unit" class="ch-sc-unit">${t('vehicle.speed_kmh')}</span>
                </div>
                <div class="ch-sc-mid">
                    <div class="ch-sc-fuel">
                        <span class="ch-icon" style="color:#FFFFFF;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                        <span id="veh-fuel-text">75L</span>
                    </div>
                    <div class="ch-bottom-icons" style="margin-top:0;">
                        ${buildTelltalesHtml()}
                    </div>
                </div>
                <div class="ch-sc-bar-track">
                    <div id="veh-simple-rpm-bar" class="ch-sc-bar-fill" style="width:0%;"></div>
                </div>
            </div>
        `;
    }

    // 6. SPORT STYLE (Bottom of image_cd4dbb.png — Twin-Wing Cluster)
    function buildSportWideTemplate(t) {
        return `
            <div class="ch-sport-wide">
                <svg class="ch-sport-svg" viewBox="0 0 410 148">
                    <!-- Sculpted Dark Glass Twin-Wing Backdrop -->
                    <path d="M 38 134 C 8 102, 10 34, 64 16 L 346 16 C 400 34, 402 102, 372 134 Z"
                        fill="rgba(8, 10, 14, 0.82)" stroke="rgba(255,255,255,0.14)" stroke-width="1.5"/>
                    <!-- Left Wing Speed/RPM Track & Active Arc -->
                    <path d="M 185 134 L 46 134 C 14 102, 18 36, 72 20 L 185 18"
                        fill="none" stroke="rgba(249, 115, 22, 0.22)" stroke-width="6" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="M 185 134 L 46 134 C 14 102, 18 36, 72 20 L 185 18"
                        fill="none" stroke="#F97316" stroke-width="6" stroke-linecap="round"
                        stroke-dasharray="390" stroke-dashoffset="390"/>
                    <!-- Right Wing Top Green Fuel Arc -->
                    <path d="M 225 18 L 338 20 C 378 32, 392 64, 386 92"
                        fill="none" stroke="rgba(132, 204, 22, 0.22)" stroke-width="5" stroke-linecap="round"/>
                    <path id="veh-arc-fuel" d="M 225 18 L 338 20 C 378 32, 392 64, 386 92"
                        fill="none" stroke="#84CC16" stroke-width="5" stroke-linecap="round"
                        stroke-dasharray="210" stroke-dashoffset="45"/>
                </svg>

                <div class="ch-sport-left-info">
                    <div class="ch-sport-gears">
                        <span id="veh-gear-prev">N</span>
                        <span id="veh-gear-val" class="active">1</span>
                        <span id="veh-gear-next">2</span>
                    </div>
                    <div class="ch-sport-speed-row">
                        <span id="veh-speed-val" class="ch-sport-speed-val">000</span>
                        <span id="veh-speed-unit" class="ch-unit-sub">${t('vehicle.speed_kmh')}</span>
                    </div>
                </div>

                <div class="ch-sport-center-car">
                    <img src="assets/images/car-topdown.svg" alt="Car" />
                </div>

                <div class="ch-sport-right-icons">
                    ${buildTelltalesHtml()}
                    <span id="veh-fuel-text" style="font-family:var(--nsr-font-mono);font-size:11px;font-weight:800;color:#84CC16;">75L</span>
                </div>
            </div>
        `;
    }

    // 7. FRAMELESS NFS HEAT PRO DIAL (Circular Tachometer with Sweeping Red Needle, Zero Rectangular Box!)
    function buildFramelessNfsDialTemplate(t) {
        const mainArc = describeArc(105, 105, 84, 140, 400);
        const redArc = describeArc(105, 105, 84, 340, 400);
        const nums = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map((n, idx) => {
            const deg = 140 + (idx / 9) * 260;
            const pt = polar(105, 105, 67, deg);
            const col = n >= 7 ? '#EF4444' : '#E2E8F0';
            return `<text x="${pt.x.toFixed(1)}" y="${pt.y.toFixed(1)}" fill="${col}" font-family="Consolas, monospace" font-weight="800" font-size="11" text-anchor="middle" dominant-baseline="central">${n}</text>`;
        }).join('');

        return `
            <div class="ch-dial-wrap">
                <div class="ch-dial-lens"></div>
                <svg class="ch-dial-svg" viewBox="0 0 210 210">
                    <path d="${mainArc}" fill="none" stroke="rgba(255,255,255,0.16)" stroke-width="6" stroke-linecap="round"/>
                    <path d="${redArc}" fill="none" stroke="rgba(239,68,68,0.40)" stroke-width="6" stroke-linecap="round"/>
                    <path id="veh-arc-rpm" d="${mainArc}" fill="none" stroke="#00E5FF" stroke-width="6" stroke-linecap="round"
                        stroke-dasharray="382" stroke-dashoffset="382"/>
                    <g>${nums}</g>
                    <g id="veh-nfs-needle" style="transform-origin:105px 105px; transform:rotate(-130deg); transition:transform 0.055s linear;">
                        <polygon points="103,112 107,112 106,34 104,34" fill="#EF4444"/>
                        <circle cx="105" cy="105" r="6" fill="#0F172A" stroke="#00E5FF" stroke-width="2"/>
                    </g>
                </svg>
                <div class="ch-dial-center" style="padding-top:16px;">
                    <div id="veh-speed-val" class="ch-speed-big italic-condensed">000</div>
                    <div id="veh-speed-unit" class="ch-unit-sub">${t('vehicle.speed_kmh')}</div>
                    <div class="ch-gear-strip" style="margin-top:2px;">
                        <span id="veh-gear-val" class="gear-active-pill">N</span>
                    </div>
                    <div class="ch-bottom-icons">${buildTelltalesHtml()}</div>
                </div>
                <div class="ch-corner-fuel-badge">
                    <span class="ch-icon" style="width:11px;height:11px;-webkit-mask-image:url('assets/icons/fuel.svg');mask-image:url('assets/icons/fuel.svg');"></span>
                    <span id="veh-fuel-text">75L</span>
                </div>
            </div>
        `;
    }

    function getWrapperAndCluster() {
        return {
            wrapper: document.getElementById('vehicle-hud-wrapper'),
            cluster: document.getElementById('vehicle-hud-cluster')
        };
    }

    function ensureClusterBuilt(styleName, category) {
        const { cluster } = getWrapperAndCluster();
        if (!cluster) return;

        const isSpecialCraft = (category === 'helicopter' || category === 'airplane' || category === 'boat');
        const key = isSpecialCraft ? `craft_${category}` : `style_${styleName}`;
        if (builtKey === key) return;

        builtKey = key;
        const t = window.NSRLocaleUI.t;
        cluster.className = `vehicle-hud-cluster preset-${styleName}`;

        if (isSpecialCraft) {
            cluster.innerHTML = buildSpecialCraftTemplate(category, t);
        } else if (styleName === 'modern') {
            cluster.innerHTML = buildModernTemplate(t);
        } else if (styleName === 'circle') {
            cluster.innerHTML = buildCircleTemplate(t);
        } else if (styleName === 'simple_racing') {
            cluster.innerHTML = buildSimpleRacingTemplate(t);
        } else if (styleName === 'simple') {
            cluster.innerHTML = buildSimpleCleanTemplate(t);
        } else if (styleName === 'sport') {
            cluster.innerHTML = buildSportWideTemplate(t);
        } else if (styleName === 'nfs_heat') {
            cluster.innerHTML = buildFramelessNfsDialTemplate(t);
        } else {
            cluster.innerHTML = buildAggressiveTemplate(t);
        }
    }

    function applyConfig(vehCfg) {
        if (!vehCfg || typeof vehCfg !== 'object') return;
        currentConfig = vehCfg;

        const { wrapper } = getWrapperAndCluster();
        if (!wrapper) return;

        builtKey = null; // Force clean template rebuild when switching preset
        wrapper.style.left = `${vehCfg.x}%`;
        wrapper.style.top = `${vehCfg.y}%`;
        wrapper.style.opacity = String(vehCfg.opacity);
        wrapper.style.transform = `scale(${vehCfg.scale})`;

        updateTelemetry(lastVehicleData);
    }

    function computeGearNeighbors(gearStr) {
        const g = String(gearStr || 'N').toUpperCase();
        if (g === 'R') return { prev: 'P', curr: 'R', next: 'N' };
        if (g === 'N' || g === 'P') return { prev: 'R', curr: 'N', next: '1' };
        const num = parseInt(g, 10);
        if (Number.isFinite(num) && num >= 1) {
            return {
                prev: num === 1 ? 'N' : String(num - 1),
                curr: String(num),
                next: String(num + 1)
            };
        }
        return { prev: 'N', curr: g, next: '2' };
    }

    function updateTelemetry(data) {
        const { wrapper } = getWrapperAndCluster();
        if (!wrapper) return;

        if (data && typeof data === 'object') {
            lastVehicleData = data;
        }

        const effectiveData = (previewInEditor && !lastVehicleData.inVehicle) ? {
            inVehicle: true,
            category: 'car',
            isDriver: true,
            speed: 185,
            unit: (currentConfig && currentConfig.speedUnit) || 'kmh',
            rpm: 0.72,
            redline: false,
            gear: '3',
            fuel: 75,
            engineHealth: 98,
            bodyHealth: 95,
            engineRunning: true,
            seatbelt: true,
            lightsOn: true,
            highBeams: false,
            indicators: 0,
            handbrake: false,
            locked: true
        } : lastVehicleData;

        if (!effectiveData || !effectiveData.inVehicle) {
            wrapper.classList.add('hidden');
            return;
        }

        wrapper.classList.remove('hidden');
        const styleName = resolveStyleName((currentConfig && currentConfig.preset) || 'aggressive');
        const cat = effectiveData.category || 'car';
        ensureClusterBuilt(styleName, cat);

        const t = window.NSRLocaleUI.t;
        const rpmVal = window.NSRPersistenceUI.clamp(Number(effectiveData.rpm) || 0, 0, 1);
        const speedNum = Math.max(0, Math.round(Number(effectiveData.speed) || 0));

        // 1. Speed & Unit
        const spdEl = document.getElementById('veh-speed-val');
        if (spdEl) {
            spdEl.textContent = String(speedNum);
        }
        const unitEl = document.getElementById('veh-speed-unit');
        if (unitEl && cat !== 'helicopter' && cat !== 'airplane') {
            const uKey = (effectiveData.unit === 'mph') ? 'vehicle.speed_mph' : 'vehicle.speed_kmh';
            unitEl.textContent = t(uKey);
        }

        // 2. Gears (`prev`, `curr`, `next`)
        const gNeighbors = computeGearNeighbors(effectiveData.gear);
        const gPrev = document.getElementById('veh-gear-prev');
        const gCurr = document.getElementById('veh-gear-val');
        const gNext = document.getElementById('veh-gear-next');
        if (gPrev) gPrev.textContent = gNeighbors.prev;
        if (gCurr) gCurr.textContent = gNeighbors.curr;
        if (gNext) gNext.textContent = gNeighbors.next;

        // 3. Altitude (Aircraft)
        const altVal = document.getElementById('veh-altitude-val');
        if (altVal && effectiveData.altitude !== undefined && effectiveData.altitude !== null) {
            altVal.textContent = String(effectiveData.altitude);
        }

        // 4. Radial RPM Arc (`#veh-arc-rpm`)
        const rpmArc = document.getElementById('veh-arc-rpm');
        if (rpmArc) {
            const maxDash = parseFloat(rpmArc.getAttribute('stroke-dasharray')) || 382;
            const offset = maxDash - (rpmVal * maxDash);
            rpmArc.style.strokeDashoffset = offset.toFixed(1);
        }

        // 5. Sweeping Needle (`#veh-nfs-needle`)
        const needle = document.getElementById('veh-nfs-needle');
        if (needle) {
            const deg = -125 + (rpmVal * 250);
            needle.style.transform = `rotate(${deg.toFixed(1)}deg)`;
        }

        // 6. Simple Racing Vertical RPM Bars (`#veh-rpm-strip`)
        const srStrip = document.getElementById('veh-rpm-strip');
        if (srStrip) {
            const activeBars = Math.round(rpmVal * 12);
            srStrip.querySelectorAll('.ch-sr-seg').forEach((seg, idx) => {
                seg.classList.toggle('active', idx < activeBars);
            });
        }

        // 7. Simple Clean Bottom Bar (`#veh-simple-rpm-bar`)
        const scBar = document.getElementById('veh-simple-rpm-bar');
        if (scBar) {
            scBar.style.width = `${Math.round(rpmVal * 100)}%`;
        }

        // 8. Fuel Arc / Bar / Text
        const fuelPct = window.NSRPersistenceUI.clamp(effectiveData.fuel !== undefined && effectiveData.fuel !== null ? effectiveData.fuel : 100, 0, 100);
        const fuelArc = document.getElementById('veh-arc-fuel');
        if (fuelArc) {
            const maxFuelDash = parseFloat(fuelArc.getAttribute('stroke-dasharray')) || 78;
            fuelArc.style.strokeDashoffset = (maxFuelDash - (fuelPct / 100) * maxFuelDash).toFixed(1);
        }
        const fuelBar = document.getElementById('veh-fuel-bar');
        if (fuelBar) {
            fuelBar.style.width = `${fuelPct}%`;
        }
        const fuelText = document.getElementById('veh-fuel-text');
        if (fuelText) {
            fuelText.textContent = `${fuelPct}L`;
        }

        // 9. Telltale Icons (Seatbelt, Engine, Lights, Lock)
        const sbIcon = document.getElementById('veh-tt-seatbelt');
        if (sbIcon) {
            if (cat !== 'car' || effectiveData.seatbelt === null || effectiveData.seatbelt === undefined) {
                sbIcon.classList.add('hidden');
            } else {
                sbIcon.classList.remove('hidden');
                const buckled = Boolean(effectiveData.seatbelt);
                sbIcon.className = `ch-telltale ${buckled ? 'on-green' : 'on-red blink'}`;
            }
        }

        const engIcon = document.getElementById('veh-tt-engine');
        if (engIcon) {
            const eHealth = Number(effectiveData.engineHealth !== undefined ? effectiveData.engineHealth : 100);
            if (!effectiveData.engineRunning) {
                engIcon.className = 'ch-telltale on-amber';
            } else if (eHealth <= 45) {
                engIcon.className = 'ch-telltale on-red blink';
            } else {
                engIcon.className = 'ch-telltale on-green';
            }
        }

        const lightsIcon = document.getElementById('veh-tt-lights');
        if (lightsIcon) {
            if (effectiveData.highBeams) {
                lightsIcon.className = 'ch-telltale on-cyan';
            } else if (effectiveData.lightsOn) {
                lightsIcon.className = 'ch-telltale on-green';
            } else {
                lightsIcon.className = 'ch-telltale';
            }
        }

        const lockIcon = document.getElementById('veh-tt-lock');
        if (lockIcon) {
            lockIcon.className = `ch-telltale ${effectiveData.locked ? 'on-amber' : 'on-green'}`;
        }
    }

    function setEditorPreview(enabled) {
        previewInEditor = Boolean(enabled);
        updateTelemetry(lastVehicleData);
    }

    function setSeatbeltImmediate(buckled) {
        if (lastVehicleData && typeof lastVehicleData === 'object') {
            lastVehicleData.seatbelt = Boolean(buckled);
        }
        const sbIcon = document.getElementById('veh-tt-seatbelt');
        if (sbIcon) {
            sbIcon.classList.remove('hidden');
            sbIcon.className = `ch-telltale ${buckled ? 'on-green' : 'on-red blink'}`;
        }
    }

    window.NSRVehicleHudUI = {
        applyConfig: applyConfig,
        updateTelemetry: updateTelemetry,
        setSeatbeltImmediate: setSeatbeltImmediate,
        setEditorPreview: setEditorPreview,
        getLastTelemetry: function () { return lastVehicleData; },
        rebuildLabels: function () {
            builtKey = null;
            if (currentConfig) applyConfig(currentConfig);
        }
    };
})(window);
