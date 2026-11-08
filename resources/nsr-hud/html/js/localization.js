/* ============================================================================
   NSR HUD ULTIMATE — NUI LOCALIZATION ENGINE (html/js/localization.js)
   Language is controlled strictly via Config.Locale in config.lua.
   Applies automatic RTL layout when Arabic ('ar') is active.
   ============================================================================ */

(function (window) {
    'use strict';

    const state = {
        locale: 'en',
        isRTL: false,
        dir: 'ltr',
        strings: {}
    };

    function init(bundle) {
        if (!bundle || typeof bundle !== 'object') return;
        state.locale = String(bundle.locale || 'en').toLowerCase();
        state.isRTL = Boolean(bundle.isRTL);
        state.dir = state.isRTL ? 'rtl' : 'ltr';
        state.strings = (bundle.strings && typeof bundle.strings === 'object') ? bundle.strings : {};

        document.documentElement.lang = state.locale;
        document.documentElement.dir = state.dir;
        document.body.classList.toggle('rtl-layout', state.isRTL);

        applyToDOM(document);
    }

    function t(key, params) {
        if (!key) return '';
        let str = state.strings[key];
        if (typeof str !== 'string') {
            str = String(key);
        }
        if (params && typeof params === 'object') {
            Object.keys(params).forEach((paramKey) => {
                const token = new RegExp('\\{' + paramKey + '\\}', 'g');
                str = str.replace(token, String(params[paramKey]));
            });
        }
        return str;
    }

    function applyToDOM(root) {
        const container = root || document;
        container.querySelectorAll('[data-i18n]').forEach((el) => {
            const key = el.getAttribute('data-i18n');
            if (key) {
                el.textContent = t(key);
            }
        });
        container.querySelectorAll('[data-i18n-title]').forEach((el) => {
            const key = el.getAttribute('data-i18n-title');
            if (key) {
                el.setAttribute('title', t(key));
            }
        });
        container.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
            const key = el.getAttribute('data-i18n-placeholder');
            if (key) {
                el.setAttribute('placeholder', t(key));
            }
        });
    }

    function formatNumber(num) {
        const n = Number(num);
        if (!Number.isFinite(n)) return '0';
        try {
            return new Intl.NumberFormat(state.locale).format(Math.round(n));
        } catch (_) {
            return String(Math.round(n));
        }
    }

    function formatCurrency(amount, symbol, position) {
        const formatted = formatNumber(amount);
        const sym = symbol || '$';
        if (position === 'suffix') {
            return formatted + ' ' + sym;
        }
        return sym + formatted;
    }

    window.NSRLocaleUI = {
        init: init,
        t: t,
        applyToDOM: applyToDOM,
        formatNumber: formatNumber,
        formatCurrency: formatCurrency,
        isRTL: function () { return state.isRTL; },
        getLocale: function () { return state.locale; }
    };
})(window);
