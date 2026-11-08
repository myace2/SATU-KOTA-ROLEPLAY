const hudElements = {
    hud: document.getElementById('status-hud'),
    health: {
        bar: document.querySelector('.health .bar-fill'),
        value: document.querySelector('.health .value')
    },
    armor: {
        bar: document.querySelector('.armor .bar-fill'),
        value: document.querySelector('.armor .value')
    },
    food: {
        bar: document.querySelector('.food .bar-fill'),
        value: document.querySelector('.food .value')
    },
    water: {
        bar: document.querySelector('.water .bar-fill'),
        value: document.querySelector('.water .value')
    },
    stress: {
        bar: document.querySelector('.stress .bar-fill'),
        value: document.querySelector('.stress .value')
    },
    drunk: {
        bar: document.querySelector('.drunk .bar-fill'),
        value: document.querySelector('.drunk .value')
    },
    energy: {
        bar: document.querySelector('.energy .bar-fill'),
        value: document.querySelector('.energy .value')
    },
    serverName: document.querySelector('.server-name-value'),
    job: document.querySelector('.job-value'),
    gang: document.querySelector('.gang-value'),
    id: document.querySelector('.id-value'),
    location: document.querySelector('.location-value')
};

const lastValues = {
    health: -1,
    armor: -1,
    food: -1,
    water: -1,
    stress: -1,
    drunk: -1,
    energy: -1
};

let updatePending = false;
let pendingUpdates = {};

function setPx(el, prop, value) {
    if (!el) return;
    el.style[prop] = `${Math.max(0, Math.floor(value))}px`;
}

function applyMinimapAvoidance(minimap) {
    const hud = document.getElementById('status-hud');
    if (!hud || !minimap) return;

    const padding = Number(minimap.padding ?? 12);
    const left = Number(minimap.left) + Number(minimap.width) + padding;
    const bottom = Number(minimap.bottom);

    setPx(hud, 'left', left);
    setPx(hud, 'bottom', bottom);

    const idEl = document.getElementById('player-id');
    const locEl = document.getElementById('player-location');
    const metaEl = document.getElementById('player-meta');
    const infoBottom = Number(minimap.bottom) + Number(minimap.height) + padding;
    const idHeight = idEl ? idEl.getBoundingClientRect().height : 0;

    setPx(metaEl, 'left', Number(minimap.left) + padding);
    setPx(metaEl, 'bottom', infoBottom + idHeight + 6);
    setPx(idEl, 'left', Number(minimap.left) + padding);
    setPx(idEl, 'bottom', infoBottom);

    if (locEl) {
        const idWidth = idEl ? idEl.getBoundingClientRect().width : 0;
        setPx(locEl, 'left', Number(minimap.left) + padding + idWidth + 10);
        setPx(locEl, 'bottom', infoBottom);
    }
}

window.addEventListener('message', function(event) {
    if (event.data.type === 'updateSpeedometer') {
        const speedometer = document.getElementById('vehicle-speedometer');
        speedometer.style.display = event.data.show ? 'block' : 'none';

        if (event.data.show) {
            const maxSpeed = Math.max(1, Number(event.data.maxSpeed) || 300);
            const speed = Math.max(0, Number(event.data.speed) || 0);
            const speedPercent = Math.min(1, speed / maxSpeed);
            const arcLength = 263.89;

            document.getElementById('speed-unit').textContent = event.data.unit || 'KM/H';
            document.getElementById('speed-value').textContent = String(speed).padStart(3, '0');
            document.getElementById('gear-value').textContent = event.data.gear;
            document.getElementById('fuel-value').textContent = `${event.data.fuel}%`;
            document.getElementById('rpm-value').textContent = `${event.data.rpm}%`;
            document.getElementById('engine-status').textContent = event.data.engine ? 'ENGINE ON' : 'ENGINE OFF';
            document.getElementById('seatbelt-status').textContent = event.data.seatbelt ? 'BELT ON' : 'BELT OFF';
            document.getElementById('gauge-fill').style.strokeDashoffset = `${arcLength * (1 - speedPercent)}`;
            document.getElementById('rpm-fill').style.width = `${event.data.rpm}%`;
        }
    }

    if (event.data.type === 'updateStatusHud') {
        if (event.data.show) {
            document.getElementById('status-hud').style.display = 'block';
        
            const idElement = document.getElementById('player-id');
            if (event.data.showId) {
                idElement.style.display = 'block';
                document.querySelector('.id-value').textContent = 'ID: ' + event.data.id;
            } else {
                idElement.style.display = 'none';
            }
            
            const locationElement = document.getElementById('player-location');
            if (event.data.showLocation) {
                locationElement.style.display = 'block';
                document.querySelector('.location-value').textContent = event.data.location || 'Unknown Location';
            } else {
                locationElement.style.display = 'none';
            }
            document.querySelector('.server-name-value').textContent = event.data.serverName || 'Server';
            document.querySelector('.job-value').textContent = event.data.job || 'Civilian';
            document.querySelector('.gang-value').textContent = event.data.gang || 'None';
            updateBar('health', Math.floor(event.data.health));
            updateBar('armor', Math.floor(event.data.armor));
            updateBar('food', Math.floor(event.data.food));
            updateBar('water', Math.floor(event.data.water));
            updateBar('stress', Math.floor(event.data.stress));
            updateBar('drunk', Math.floor(event.data.drunk));
            updateBar('energy', Math.floor(event.data.energy));
        } else {
            document.getElementById('status-hud').style.display = 'none';
        }
    }

    if (event.data.type === 'updateMinimap') {
        applyMinimapAvoidance(event.data);
    }
});

function updateHUD() {
    updatePending = false;
    Object.entries(pendingUpdates).forEach(([type, value]) => {
        if (value !== lastValues[type]) {
            const element = hudElements[type];
            if (element) {
                element.bar.style.width = `${value}%`;
                element.value.textContent = `${value}%`;
                lastValues[type] = value;
            }
        }
    });
}

function updateBar(type, value) {
    const bar = document.querySelector('.' + type + ' .bar-fill');
    const valueElement = document.querySelector('.' + type + ' .value');
    if (bar && valueElement) {
        value = Math.max(0, Math.min(100, Math.floor(Number(value) || 0)));
        bar.style.width = value + '%';
        valueElement.textContent = value + '%';
    }
}
