
'use strict';

/* ─────────────────────────────────────────────────────────────
   TARGET → QR MAP
   Index must match the order images were compiled into targets.mind
───────────────────────────────────────────────────────────── */
const TARGET_QR_MAP = {
  0: 'ARTIFACT-PAINT-001',   // Spoliarium
  1: 'ARTIFACT-PAINT-002',   // The Parisian Life
  2: 'ARTIFACT-PAINT-003',   // Blood Compact
  // 3: 'ARTIFACT-PAINT-004', ← add more here
};

const LANGS       = ['EN', 'KR', 'JP', 'CH'];
let   currentLang = 'EN';

const paintingCache = new Map();

const openPanels = new Set();

const API_BASE = 'api';

async function fetchPaintingData(qrValue, langCode) {
  const key = `${qrValue}::${langCode}`;
  if (paintingCache.has(key)) return paintingCache.get(key);

  const url = `${API_BASE}/get_painting.php?` +
    new URLSearchParams({ qr_value: qrValue, language_code: langCode });

  const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);

  const data = await res.json();
  if (!data.success) throw new Error(data.error || 'API error');

  paintingCache.set(key, data);
  return data;
}

function truncate(str, maxChars) {
  if (!str) return '';
  str = str.trim();
  return str.length <= maxChars ? str : str.slice(0, maxChars).trimEnd() + '…';
}

let _toastTimer = null;
function showToast(msg, ms = 3000) {
  const el = document.getElementById('toast');
  if (!el) return;
  clearTimeout(_toastTimer);
  el.textContent = msg;
  el.classList.add('show');
  _toastTimer = setTimeout(() => el.classList.remove('show'), ms);
}

function setLoadingProgress(pct, msg) {
  const bar    = document.getElementById('loading-bar');
  const status = document.getElementById('loading-status');
  if (bar)    bar.style.width = pct + '%';
  if (status && msg) status.textContent = msg;
}

function hideLoadingScreen() {
  setLoadingProgress(100, 'AR Ready');
  setTimeout(() => {
    const ls = document.getElementById('loading-screen');
    if (ls) ls.classList.add('fade-out');
  }, 500);
}

function showHtmlEl(id, show) {
  const el = document.getElementById(id);
  if (!el) return;
  show ? el.classList.remove('hidden') : el.classList.add('hidden');
}

AFRAME.registerComponent('ar-target', {
  schema: {
    qrValue: { type: 'string', default: '' },
    idx:     { type: 'int',    default: 0  },
  },

  init: function () {
    const { qrValue, idx } = this.data;

    this.el.addEventListener('targetFound', async () => {
      console.log(`[ArtiFact] Target ${idx} found — ${qrValue}`);
      showHtmlEl('scan-hint', false);
      showHtmlEl('lang-switcher', true);

      try {
        const data = await fetchPaintingData(qrValue, currentLang);
        const titleEl = document.getElementById(`t${idx}-title`);
        if (titleEl) {
          titleEl.setAttribute('value', truncate(data.title_text || data.painting_title, 28));
        }
        if (data.is_fallback_language) {
          showToast('Translation unavailable — showing English');
        }
      } catch (err) {
        console.warn(`[ArtiFact] Pre-fetch failed for target ${idx}:`, err);
      }
    });

    this.el.addEventListener('targetLost', () => {
      console.log(`[ArtiFact] Target ${idx} lost`);

      const panel = document.getElementById(`panel-${idx}`);
      if (panel) panel.setAttribute('visible', false);
      openPanels.delete(idx);

      const titleEl = document.getElementById(`t${idx}-title`);
      if (titleEl) titleEl.setAttribute('value', '—');

      setTimeout(() => {
        if (openPanels.size === 0) showHtmlEl('scan-hint', true);
      }, 400);
    });
  },
});

AFRAME.registerComponent('painting-btn', {
  schema: {
    action: { type: 'string', default: '' },
    idx:    { type: 'int',    default: 0  },
  },

  init: function () {
    this.el.addEventListener('click', this.handleClick.bind(this));

    this.el.addEventListener('mouseenter', () => {
      this.el.setAttribute('material', 'color: #e4c97e');
    });
    this.el.addEventListener('mouseleave', () => {
      
      const baseColor = this.data.action === 'language' ? '#0b1630' : '#c9a84c';
      this.el.setAttribute('material', `color: ${baseColor}`);
    });
  },

  handleClick: async function () {
    const { action, idx } = this.data;
    const qrValue = TARGET_QR_MAP[idx];

    if (!qrValue) {
      console.warn(`[ArtiFact] No QR mapping for target idx ${idx}`);
      return;
    }

    // ── Language toggle: no panel, just cycle and re-fetch title ────────────
    if (action === 'language') {
      const nextIdx  = (LANGS.indexOf(currentLang) + 1) % LANGS.length;
      currentLang    = LANGS[nextIdx];

      // Update ALL lang button labels (all visible targets)
      Object.keys(TARGET_QR_MAP).forEach(i => {
        const labelEl = document.getElementById(`t${i}-lang-label`);
        if (labelEl) labelEl.setAttribute('value', currentLang);
      });

      // Update HTML switcher buttons
      document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.lang === currentLang);
      });

      showToast(`Language: ${currentLang}`);

      // Refresh open panel and title with new language
      try {
        const data = await fetchPaintingData(qrValue, currentLang);
        const titleEl = document.getElementById(`t${idx}-title`);
        if (titleEl) titleEl.setAttribute('value', truncate(data.title_text || data.painting_title, 28));

        // If a panel is open for this target, refresh its content
        const panel = document.getElementById(`panel-${idx}`);
        if (panel && panel.getAttribute('visible') === true) {
          const labelEl   = document.getElementById(`p${idx}-label`);
          const contentEl = document.getElementById(`p${idx}-content`);
          if (labelEl && contentEl) {
            const currentAction = panel.dataset.lastAction || 'artist';
            const text = getPanelText(data, currentAction);
            contentEl.setAttribute('value', text);
          }
        }
      } catch (err) {
        console.warn('[ArtiFact] Language refresh failed:', err);
      }
      return;
    }

    // ── Info actions: fetch → populate → show panel ──────────────────────────
    const panel    = document.getElementById(`panel-${idx}`);
    const labelEl  = document.getElementById(`p${idx}-label`);
    const contentEl = document.getElementById(`p${idx}-content`);

    if (!panel || !labelEl || !contentEl) return;

    // Show panel immediately with "Loading…"
    panel.setAttribute('visible', true);
    panel.dataset.lastAction = action;
    openPanels.add(idx);
    labelEl.setAttribute('value',   ACTION_LABELS[action] || action.toUpperCase());
    contentEl.setAttribute('value', 'Loading…');

    try {
      const data = await fetchPaintingData(qrValue, currentLang);
      const text = getPanelText(data, action);
      contentEl.setAttribute('value', text);

      if (data.is_fallback_language) {
        showToast('Translation unavailable — showing English');
      }
    } catch (err) {
      console.error('[ArtiFact] API fetch failed:', err);
      contentEl.setAttribute('value', 'Could not load data.\nCheck server connection.');
    }
  },
});


AFRAME.registerComponent('close-panel', {
  schema: {
    idx: { type: 'int', default: 0 },
  },
  init: function () {
    this.el.addEventListener('click', () => {
      const panel = document.getElementById(`panel-${this.data.idx}`);
      if (panel) panel.setAttribute('visible', false);
      openPanels.delete(this.data.idx);
    });

    this.el.addEventListener('mouseenter', () =>
      this.el.setAttribute('material', 'color: #e4c97e')
    );
    this.el.addEventListener('mouseleave', () =>
      this.el.setAttribute('material', 'color: #c9a84c')
    );
  },
});

const ACTION_LABELS = {
  artist:      'ARTIST',
  description: 'ABOUT THIS WORK',
  history:     'HISTORICAL BACKGROUND',
};

function getPanelText(data, action) {
  switch (action) {
    case 'artist':
      // Keep short — just name and year
      return `${data.artist_name}\nb. ${data.year_created}`;

    case 'description':
      // ~300 chars comfortably fits with wrap-count="34"
      return truncate(data.description_text, 300);

    case 'history':
      // History text can be very long — truncate to ~400 chars
      return truncate(data.historical_background_text, 400);

    default:
      return '';
  }
}

document.addEventListener('DOMContentLoaded', () => {
  setLoadingProgress(30, 'Loading AR libraries…');

  const scene = document.querySelector('a-scene');
  if (!scene) {
    console.error('[ArtiFact] <a-scene> not found.');
    return;
  }

  scene.addEventListener('loaded', () => {
    setLoadingProgress(80, 'Starting camera…');
  });

  scene.addEventListener('arReady', () => {
    console.log('[ArtiFact] AR ready');
    setLoadingProgress(100, 'Ready');
    hideLoadingScreen();
    showHtmlEl('scan-hint', true);
  });

  scene.addEventListener('arError', (e) => {
    console.error('[ArtiFact] AR error:', e);
    setLoadingProgress(0, 'AR failed — check console (F12)');
    showToast('AR failed to start. Check camera permission and targets.mind path.');
    hideLoadingScreen();
  });

  // Fallback: if arReady never fires within 15 s, hide loading anyway
  setTimeout(() => {
    const ls = document.getElementById('loading-screen');
    if (ls && !ls.classList.contains('fade-out')) {
      console.warn('[ArtiFact] arReady timeout — hiding loading screen');
      hideLoadingScreen();
      showHtmlEl('scan-hint', true);
    }
  }, 15000);
});


document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const lang = btn.dataset.lang;
      if (lang === currentLang) return;
      currentLang = lang;

      // Sync HTML buttons
      document.querySelectorAll('.lang-btn').forEach(b =>
        b.classList.toggle('active', b.dataset.lang === lang)
      );

      // Sync all 3D lang labels and invalidate cached panel content
      Object.keys(TARGET_QR_MAP).forEach(i => {
        const labelEl = document.getElementById(`t${i}-lang-label`);
        if (labelEl) labelEl.setAttribute('value', lang);
      });

      // Bust title cache so next targetFound re-fetches in new lang
  
      showToast(`Language: ${lang}`);
    });
  });
});
