
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const backBtn = document.getElementById('backBtn');

const categoryContent = document.getElementById('categoryContent');
const submenuContent = document.getElementById('submenuContent');
const categoryTitle = document.getElementById('categoryTitle');
const categoryDescription = document.getElementById('categoryDescription');
const submenuTitle = document.getElementById('submenuTitle');
const optionList = document.getElementById('optionList');

const categoryButtons = document.querySelectorAll('.category-btn');

let currentCategory = 'performance';
let performanceOptions = [];

/*
|--------------------------------------------------------------------------
| NUI COMMUNICATION
|--------------------------------------------------------------------------
*/

function postNui(eventName, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).then(response => response.json()).catch(error => {
        console.error(`NUI callback error: ${eventName}`, error);
        return null;
    });
}

/*
|--------------------------------------------------------------------------
| MAIN MENU
|--------------------------------------------------------------------------
*/


function openMainMenu(data = {}) {
    app.classList.remove('hidden');

    categoryContent.classList.remove('hidden');
    submenuContent.classList.add('hidden');

    categoryTitle.textContent = 'Vehicle Customization';
    categoryDescription.textContent =
        'Select a category to customize your vehicle.';

    optionList.innerHTML = '';

    const allowedCategories = Array.isArray(data.categories)
        ? data.categories
        : ['performance', 'parts', 'colors', 'extras', 'repair'];

    categoryButtons.forEach(button => {
        const category = button.dataset.category;

        button.classList.toggle(
            'hidden',
            !allowedCategories.includes(category)
        );
    });

    if (!allowedCategories.includes(currentCategory)) {
        setActiveCategory(allowedCategories[0] || '');
    }
}


function closeMenu() {
    app.classList.add('hidden');
    postNui('close');
}

function setActiveCategory(category) {
    currentCategory = category;

    categoryButtons.forEach(button => {
        button.classList.toggle(
            'active',
            button.dataset.category === category
        );
    });
}

/*
|--------------------------------------------------------------------------
| CATEGORY SELECTION
|--------------------------------------------------------------------------
*/

const categoryInformation = {
    performance: {
        title: 'Performance Upgrade',
        description: 'Improve your vehicle performance and driving experience.'
    },

    parts: {
        title: 'Vehicle Parts',
        description: 'Customize vehicle components and accessories.'
    },

    colors: {
        title: 'Vehicle Colors',
        description: 'Customize paint, lighting, and vehicle appearance.'
    },

    extras: {
        title: 'Vehicle Extras',
        description: 'Manage additional vehicle accessories.'
    },

    repair: {
        title: 'Vehicle Repair',
        description: 'Restore your vehicle to its original condition.'
    }
};

function selectCategory(category) {
    if (!categoryInformation[category]) return;

    setActiveCategory(category);

    postNui('selectCategory', {
        category: category
    });
}

categoryButtons.forEach(button => {
    button.addEventListener('click', () => {
        const category = button.dataset.category;

        if (category) {
            selectCategory(category);
        }
    });
});

/*
|--------------------------------------------------------------------------
| PERFORMANCE SUBMENU
|--------------------------------------------------------------------------
*/

function showPerformanceMenu(data) {
    const options = Array.isArray(data.options)
        ? data.options
        : [];

    performanceOptions = options;

    app.classList.remove('hidden');
    categoryContent.classList.add('hidden');
    submenuContent.classList.remove('hidden');

    submenuTitle.textContent = 'Performance Upgrade';

    optionList.innerHTML = '';

    if (options.length === 0) {
        optionList.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">⚙</div>
                <h3>No Upgrade Available</h3>
                <p>This vehicle does not have available performance upgrades.</p>
            </div>
        `;
        return;
    }

    options.forEach((option, optionIndex) => {
        const card = document.createElement('div');
        card.className = 'upgrade-card';

        const label = document.createElement('div');
        label.className = 'upgrade-info';

        const title = document.createElement('h3');
        title.textContent = option.label || 'Vehicle Upgrade';

        const description = document.createElement('p');
        description.textContent = option.description || '';

        label.appendChild(title);
        label.appendChild(description);

        const controls = document.createElement('div');
        controls.className = 'upgrade-controls';

        const select = document.createElement('select');
        select.className = 'upgrade-select';

        const values = Array.isArray(option.values)
            ? option.values
            : [];

        values.forEach((value, index) => {
            const item = document.createElement('option');

            item.value = index + 1;
            item.textContent = value;

            if ((index + 1) === option.defaultIndex) {
                item.selected = true;
            }

            select.appendChild(item);
        });

        const installButton = document.createElement('button');
        installButton.className = 'install-btn';
        installButton.textContent = 'Install';

        select.addEventListener('change', () => {
            postNui('performancePreview', {
                id: option.id,
                index: Number(select.value)
            });
        });

        installButton.addEventListener('click', () => {
            installButton.disabled = true;
            installButton.textContent = 'Processing...';

            postNui('performanceInstall', {
                id: option.id,
                index: Number(select.value)
            }).finally(() => {
                installButton.disabled = false;
                installButton.textContent = 'Install';
            });
        });

        controls.appendChild(select);
        controls.appendChild(installButton);

        card.appendChild(label);
        card.appendChild(controls);

        optionList.appendChild(card);
    });
}

/*
|--------------------------------------------------------------------------
| BACK TO MAIN MENU
|--------------------------------------------------------------------------
*/

function backToMain() {
    postNui('performanceBack');
}

/*
|--------------------------------------------------------------------------
| BUTTON EVENTS
|--------------------------------------------------------------------------
*/

closeBtn.addEventListener('click', closeMenu);

backBtn.addEventListener('click', backToMain);

/*
|--------------------------------------------------------------------------
| LUA -> JAVASCRIPT MESSAGES
|--------------------------------------------------------------------------
*/

window.addEventListener('message', (event) => {
    const data = event.data;

    if (!data || !data.action) return;

    switch (data.action) {

        case 'open':
            openMainMenu(data);
            break;

        case 'close':
            app.classList.add('hidden');
            break;

        case 'performance':
            showPerformanceMenu(data);
            break;

        case 'backToMain':
            openMainMenu();
            break;

        case 'updatePerformance':
            showPerformanceMenu(data);
            break;
    }
});

/*
|--------------------------------------------------------------------------
| KEYBOARD CONTROLS
|--------------------------------------------------------------------------
*/

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !app.classList.contains('hidden')) {
        event.preventDefault();
        closeMenu();
    }
});
