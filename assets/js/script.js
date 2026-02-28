'use strict';

/* ─────────────────────────────────────────────────────────────
   TARGET → QR MAP
───────────────────────────────────────────────────────────── */
const TARGET_QR_MAP = {
  0: 'ARTIFACT-PAINT-001',   // Spoliarium
  1: 'ARTIFACT-PAINT-002',   
  2: 'ARTIFACT-PAINT-003',   
};

const LANGS = ['EN', 'KR', 'JP', 'CH'];
let currentLang = 'EN';

const paintingCache = new Map();
const activeOverlays = new Set();


/* ─────────────────────────────────────────────────────────────
   API_BASE — works for ALL common local setups:
     XAMPP/WAMP root:   http://localhost/artifact/
     php -S localhost:8000 from project root
     XAMPP subfolder:   http://localhost/myproject/
   
   Strategy: derive the path to /api/ relative to index.html's
   actual location so it works no matter the subfolder depth.
───────────────────────────────────────────────────────────── */
const API_BASE = (() => {
  // window.location.href when index.html is open, e.g.:
  //   http://localhost/artifact/index.html  → .../artifact/api
  //   http://localhost:8000/index.html      → .../api
  const href = window.location.href;
  // Strip filename + query, keep trailing slash on the folder
  const folder = href.substring(0, href.lastIndexOf('/') + 1);
  return folder + 'api';
})();

/* ─────────────────────────────────────────────────────────────
   API
───────────────────────────────────────────────────────────── */
async function fetchPaintingData(qrValue, langCode) {
  const key = `${qrValue}::${langCode}`;
  if (paintingCache.has(key)) return paintingCache.get(key);

  const url = `${API_BASE}/get_painting.php?` +
    new URLSearchParams({ qr_value: qrValue, language_code: langCode });

  console.log('[ArtiFact] Fetching:', url);   

  let res;
  try {
    res = await fetch(url, { headers: { 'Accept': 'application/json' } });
  } catch (networkErr) {
    throw new Error('Network error — is PHP server running? ' + networkErr.message);
  }

  if (!res.ok) {
    let body = '';
    try { body = await res.text(); } catch (_) { }
    throw new Error(`HTTP ${res.status} — ${body.slice(0, 300)}`);
  }

  let data;
  try {
    data = await res.json();
  } catch (parseErr) {
    throw new Error('API returned non-JSON (PHP error?). ' + parseErr.message);
  }

  if (!data.success) throw new Error(data.error || 'API returned success:false');

  paintingCache.set(key, data);
  return data;
}

function truncate(str, maxChars) {
  if (!str) return '';
  str = str.trim();
  return str.length <= maxChars ? str : str.slice(0, maxChars).trimEnd() + '…';
}

let _toastTimer = null;
function showToast(msg, ms = 3500) {
  const el = document.getElementById('toast');
  if (!el) return;
  clearTimeout(_toastTimer);
  el.textContent = msg;
  el.classList.add('show');
  _toastTimer = setTimeout(() => el.classList.remove('show'), ms);
}

function setLoadingProgress(pct, msg) {
  const bar = document.getElementById('loading-bar');
  const status = document.getElementById('loading-status');
  if (bar) bar.style.width = pct + '%';
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

const trackerMap = {};

function showOverlay(idx) {
  const ov = document.getElementById(`overlay-${idx}`);
  if (ov) {
    ov.classList.remove('hidden');
    // Trigger re-animation on re-detection
    ov.classList.remove('overlay-visible');
    void ov.offsetWidth;                     // force reflow
    ov.classList.add('overlay-visible');
  }
  activeOverlays.add(idx);
}

function hideOverlay(idx) {
  const ov = document.getElementById(`overlay-${idx}`);
  if (ov) {
    ov.classList.add('hidden');
    ov.classList.remove('overlay-visible');
  }
  closePanel(idx);
  activeOverlays.delete(idx);
}

function setOverlayTitle(idx, text) {
  const el = document.getElementById(`ov${idx}-title`);
  if (el) el.textContent = text || '—';
}

function setOverlayLang(idx, lang) {
  const el = document.getElementById(`ov${idx}-lang`);
  if (el) el.textContent = lang;
}

function openPanel(idx, label, content) {
  const panel = document.getElementById(`panel-${idx}`);
  const labelEl = document.getElementById(`p${idx}-label`);
  const contEl = document.getElementById(`p${idx}-content`);
  if (!panel) return;
  if (labelEl) labelEl.textContent = label;
  if (contEl) contEl.textContent = content;
  panel.classList.remove('hidden');
}

function closePanel(idx) {
  const panel = document.getElementById(`panel-${idx}`);
  if (panel) {
    panel.classList.add('hidden');
    panel.dataset.lastAction = '';
  }
}

const ACTION_LABELS = {
  artist: 'ARTIST',
  description: 'ABOUT THIS WORK',
  history: 'HISTORICAL BACKGROUND',
};

function getPanelText(data, action) {
  switch (action) {
    case 'artist': {
      const year = data.year_created && data.year_created !== 0
        ? `b. ${data.year_created}`
        : '';
      return [data.artist_name, year].filter(Boolean).join('\n');
    }
    case 'description': return data.description_text?.trim() || '';
    case 'history': return data.historical_background_text?.trim() || '';
    default: return '';
  }
}

function syncLangUI(lang) {
  document.querySelectorAll('.lang-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.lang === lang)
  );
  Object.keys(TARGET_QR_MAP).forEach(i => setOverlayLang(i, lang));
}

const _worldPos = new THREE.Vector3();
const _screenVec = new THREE.Vector3();

/**
 * Returns { x, y } in CSS pixels (origin: top-left of viewport).
 * Returns null if the scene/camera isn't ready yet.
 *
 * @param {THREE.Object3D} object3D  — the A-Frame entity's object3D
 * @param {number} worldOffsetY      — optional vertical world-unit nudge
 *                                     (use to push the overlay below the target)
 */
function worldToScreen(object3D) {
  const scene = document.querySelector('a-scene');
  if (!scene || !scene.camera) return null;

  const camera = scene.camera;
  const renderer = scene.renderer;
  if (!renderer) return null;

  object3D.getWorldPosition(_worldPos);
  _screenVec.copy(_worldPos).project(camera);

  const canvas = renderer.domElement;
  const w = canvas.clientWidth || window.innerWidth;
  const h = canvas.clientHeight || window.innerHeight;

  return {
    x: (_screenVec.x + 1) / 2 * w,
    y: (-_screenVec.y + 1) / 2 * h,
  };
}

const OVERLAY_OFFSET_Y = 100;    
const OVERLAY_OFFSET_X = 0;    

const LERP = 0.38;

function trackingLoop() {
  for (const [idxStr, tracker] of Object.entries(trackerMap)) {
    const idx = parseInt(idxStr, 10);
    if (!tracker.active || !tracker.object3D) continue;

    const ov = document.getElementById(`overlay-${idx}`);
    if (!ov || ov.classList.contains('hidden')) continue;

    const centre = worldToScreen(tracker.object3D);
    if (!centre) continue;

    const pos = {
      x: centre.x + OVERLAY_OFFSET_X,
      y: centre.y + OVERLAY_OFFSET_Y,
    };

    if (tracker.screenX === undefined) {
      tracker.screenX = pos.x;
      tracker.screenY = pos.y;
    }

    tracker.screenX += (pos.x - tracker.screenX) * LERP;
    tracker.screenY += (pos.y - tracker.screenY) * LERP;

    const ovW = ov.offsetWidth || 320;
    const ovH = ov.offsetHeight || 120;
    const vw = window.innerWidth;
    const vh = window.innerHeight;

    const cx = Math.max(ovW / 2 + 8, Math.min(vw - ovW / 2 - 8, tracker.screenX));
    const cy = Math.max(8, Math.min(vh - ovH - 8, tracker.screenY));

    ov.style.left = `${cx}px`;
    ov.style.top = `${cy}px`;
    ov.style.transform = 'translate(-50%, 0)';
  }

  requestAnimationFrame(trackingLoop);
}

AFRAME.registerComponent('ar-target', {
  schema: {
    qrValue: { type: 'string', default: '' },
    idx: { type: 'int', default: 0 },
  },

  init: function () {
    const { qrValue, idx } = this.data;

    // Register this entity so the tracking loop can find its 3D object
    trackerMap[idx] = {
      object3D: this.el.object3D,
      active: false,
      screenX: undefined,
      screenY: undefined,
    };

    this.el.addEventListener('targetFound', async () => {
      console.log(`[ArtiFact] Target ${idx} found — ${qrValue}`);
      trackerMap[idx].active = true;
      trackerMap[idx].screenX = undefined;  // reset so first frame snaps
      trackerMap[idx].screenY = undefined;
      showOverlay(idx);
      showHtmlEl('scan-hint', false);
      showHtmlEl('lang-switcher', true);
      document.body.classList.add('spotlight');

      try {
        const data = await fetchPaintingData(qrValue, currentLang);
        setOverlayTitle(idx, data.title_text || data.painting_title);
        if (data.is_fallback_language) showToast('Translation unavailable — showing English');
      } catch (err) {
        console.error(`[ArtiFact] Pre-fetch failed:`, err);
        showToast('Could not load painting — ' + err.message);
      }
    });

    this.el.addEventListener('targetLost', () => {
      console.log(`[ArtiFact] Target ${idx} lost`);
      trackerMap[idx].active = false;
      hideOverlay(idx);
      setOverlayTitle(idx, '—');
      if (activeOverlays.size === 0) document.body.classList.remove('spotlight');
      setTimeout(() => {
        if (activeOverlays.size === 0) showHtmlEl('scan-hint', true);
      }, 400);
    });
  },
});

/* ─────────────────────────────────────────────────────────────
   DOM READY — safe whether script is in <head> or <body>
───────────────────────────────────────────────────────────── */
function onDOMReady(fn) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', fn, { once: true });
  } else {
    fn();
  }
}

onDOMReady(() => {

  // Confirm API_BASE in console so you can verify immediately
  console.log('[ArtiFact] API_BASE =', API_BASE);

  /* ── Action buttons ── */
  document.querySelectorAll('.ar-action-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const idx = parseInt(btn.dataset.idx, 10);
      const action = btn.dataset.action;
      const qrValue = TARGET_QR_MAP[idx];
      if (!qrValue) return;

      const label = ACTION_LABELS[action] || action.toUpperCase();
      openPanel(idx, label, 'Loading…');
      document.getElementById(`panel-${idx}`).dataset.lastAction = action;

      try {
        const data = await fetchPaintingData(qrValue, currentLang);
        const contEl = document.getElementById(`p${idx}-content`);
        if (contEl) contEl.textContent = getPanelText(data, action);
        if (data.is_fallback_language) showToast('Translation unavailable — showing English');
      } catch (err) {
        console.error('[ArtiFact] Action fetch failed:', err);
        const contEl = document.getElementById(`p${idx}-content`);
        if (contEl) contEl.textContent = 'Could not load data.\n' + err.message;
        showToast('API error — see console (F12)');
      }
    });
  });

  /* ── Language cycle buttons ── */
  document.querySelectorAll('.ar-lang-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const idx = parseInt(btn.dataset.idx, 10);
      currentLang = LANGS[(LANGS.indexOf(currentLang) + 1) % LANGS.length];
      syncLangUI(currentLang);
      showToast(`Language: ${currentLang}`);

      const qrValue = TARGET_QR_MAP[idx];
      if (!qrValue) return;
      try {
        const data = await fetchPaintingData(qrValue, currentLang);
        setOverlayTitle(idx, data.title_text || data.painting_title);
        const panel = document.getElementById(`panel-${idx}`);
        if (panel && !panel.classList.contains('hidden') && panel.dataset.lastAction) {
          const contEl = document.getElementById(`p${idx}-content`);
          if (contEl) contEl.textContent = getPanelText(data, panel.dataset.lastAction);
        }
      } catch (err) {
        console.warn('[ArtiFact] Language refresh failed:', err);
      }
    });
  });

  /* ── Close buttons ── */
  document.querySelectorAll('.ar-panel-close').forEach(btn => {
    btn.addEventListener('click', () => closePanel(parseInt(btn.dataset.idx, 10)));
  });

  /* ── HTML language switcher ── */
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const lang = btn.dataset.lang;
      if (lang === currentLang) return;
      currentLang = lang;
      syncLangUI(lang);
      showToast(`Language: ${lang}`);

      // Refresh every active overlay with the new language
      for (const idx of activeOverlays) {
        const qrValue = TARGET_QR_MAP[idx];
        if (!qrValue) continue;
        try {
          const data = await fetchPaintingData(qrValue, lang);
          setOverlayTitle(idx, data.title_text || data.painting_title);
          if (data.is_fallback_language) showToast('Translation unavailable — showing English');

          // If a panel is open, refresh its content too
          const panel = document.getElementById(`panel-${idx}`);
          if (panel && !panel.classList.contains('hidden') && panel.dataset.lastAction) {
            const contEl = document.getElementById(`p${idx}-content`);
            if (contEl) contEl.textContent = getPanelText(data, panel.dataset.lastAction);
          }
        } catch (err) {
          console.warn(`[ArtiFact] Language refresh failed for idx ${idx}:`, err);
        }
      }
    });
  });

  /* ── Scene lifecycle ── */
  setLoadingProgress(30, 'Loading AR libraries…');
  const scene = document.querySelector('a-scene');
  if (!scene) { console.error('[ArtiFact] <a-scene> not found.'); return; }

  scene.addEventListener('loaded', () => setLoadingProgress(80, 'Starting camera…'));
  scene.addEventListener('arReady', () => {
    console.log('[ArtiFact] AR ready');
    hideLoadingScreen();
    showHtmlEl('scan-hint', true);
    // Start the world→screen projection loop
    requestAnimationFrame(trackingLoop);
  });
  scene.addEventListener('arError', (e) => {
    console.error('[ArtiFact] AR error:', e);
    setLoadingProgress(0, 'AR failed — check console');
    showToast('AR failed to start. Check camera permission.');
    hideLoadingScreen();
  });

  setTimeout(() => {
    const ls = document.getElementById('loading-screen');
    if (ls && !ls.classList.contains('fade-out')) {
      console.warn('[ArtiFact] arReady timeout — forcing hide');
      hideLoadingScreen();
      showHtmlEl('scan-hint', true);
    }
  }, 15000);
});