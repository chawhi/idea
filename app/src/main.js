import { pdfFileToImages, imageFileToImage } from "./pdfLoader.js";
import {
  loadProject,
  saveProject,
  clearStoredProject,
  exportProjectFile,
  importProjectFile,
} from "./storage.js";
import { Playback } from "./playback.js";

const els = {
  modeEditBtn: document.getElementById("modeEditBtn"),
  modePlayBtn: document.getElementById("modePlayBtn"),
  fileInput: document.getElementById("fileInput"),
  exportBtn: document.getElementById("exportBtn"),
  importInput: document.getElementById("importInput"),
  clearBtn: document.getElementById("clearBtn"),
  bpmInput: document.getElementById("bpmInput"),
  bpmUp: document.getElementById("bpmUp"),
  bpmDown: document.getElementById("bpmDown"),
  tapTempoBtn: document.getElementById("tapTempoBtn"),
  playBtn: document.getElementById("playBtn"),
  stopBtn: document.getElementById("stopBtn"),
  loopToggle: document.getElementById("loopToggle"),
  metronomeToggle: document.getElementById("metronomeToggle"),
  sidebarToggleBtn: document.getElementById("sidebarToggleBtn"),
  sidebarCloseBtn: document.getElementById("sidebarCloseBtn"),
  sidebar: document.getElementById("sidebar"),
  regionList: document.getElementById("regionList"),
  pagesContainer: document.getElementById("pagesContainer"),
  toast: document.getElementById("toast"),
};

const defaultState = () => ({
  pages: [],
  regions: [],
  bpm: 90,
  loop: true,
  metronomeOn: true,
});

let state = defaultState();
let mode = "edit";
let sidebarOpen = false;
let pendingStartIndex = 0;
let tapTimes = [];

let pageWrapperById = new Map();
let regionElsById = new Map();

const playback = new Playback({
  getRegions: () => state.regions,
  getBpm: () => state.bpm,
  getLoop: () => state.loop,
  getMetronomeOn: () => state.metronomeOn,
  onRegionChange: (idx, region) => highlightRegion(idx, region),
  onStop: () => updatePlayButton(false),
});

function uid() {
  if (crypto.randomUUID) return crypto.randomUUID();
  return `id-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

let toastTimer = null;
function showToast(message, ms = 3000) {
  els.toast.textContent = message;
  els.toast.classList.remove("hidden");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => els.toast.classList.add("hidden"), ms);
}

function persist() {
  if (!saveProject(state)) {
    showToast("保存に失敗しました（容量オーバーの可能性）。「書き出し」でバックアップしてください。", 5000);
  }
}

function beatsBeforeIndex(idx) {
  let sum = 0;
  for (let i = 0; i < idx && i < state.regions.length; i++) sum += state.regions[i].beats;
  return sum;
}

// --- Rendering ---------------------------------------------------------

function renderAll() {
  els.bpmInput.value = state.bpm;
  els.loopToggle.checked = state.loop;
  els.metronomeToggle.checked = state.metronomeOn;
  renderPages();
  renderRegionList();
}

function renderPages() {
  pageWrapperById = new Map();
  regionElsById = new Map();
  els.pagesContainer.innerHTML = "";

  if (!state.pages.length) {
    const hint = document.createElement("p");
    hint.className = "empty-hint";
    hint.innerHTML =
      "上の「譜面を取り込む」から画像またはPDFを追加してください。<br />" +
      "編集モードでは、譜面上をドラッグして演奏順に区間（小節・行など）を矩形で囲んでいきます。";
    els.pagesContainer.appendChild(hint);
    return;
  }

  state.pages.forEach((page, pageIdx) => {
    const wrapper = document.createElement("div");
    wrapper.className = "page-wrapper";

    const label = document.createElement("div");
    label.className = "page-label";
    label.textContent = `ページ ${pageIdx + 1}`;
    wrapper.appendChild(label);

    const img = document.createElement("img");
    img.src = page.src;
    img.draggable = false;
    img.alt = `ページ ${pageIdx + 1}`;
    wrapper.appendChild(img);

    attachDrawHandlers(wrapper, page.id);
    els.pagesContainer.appendChild(wrapper);
    pageWrapperById.set(page.id, wrapper);
  });

  renderRegionBoxes();
}

function renderRegionBoxes() {
  pageWrapperById.forEach((wrapper) => {
    wrapper.querySelectorAll(".region-box").forEach((el) => el.remove());
  });
  regionElsById = new Map();

  state.regions.forEach((region, idx) => {
    const wrapper = pageWrapperById.get(region.pageId);
    if (!wrapper) return;

    const box = document.createElement("div");
    box.className = "region-box";
    box.style.left = `${region.xPct * 100}%`;
    box.style.top = `${region.yPct * 100}%`;
    box.style.width = `${region.wPct * 100}%`;
    box.style.height = `${region.hPct * 100}%`;

    const badge = document.createElement("span");
    badge.className = "region-index";
    badge.textContent = String(idx + 1);
    box.appendChild(badge);

    box.addEventListener("click", (e) => {
      e.stopPropagation();
      onRegionItemClick(idx);
    });

    wrapper.appendChild(box);
    regionElsById.set(region.id, box);
  });
}

function renderRegionList() {
  els.regionList.innerHTML = "";

  state.regions.forEach((region, idx) => {
    const li = document.createElement("li");
    li.className = "region-item";
    li.dataset.index = String(idx);

    const label = document.createElement("span");
    label.className = "region-label";
    const pageIdx = state.pages.findIndex((p) => p.id === region.pageId);
    label.textContent = `${idx + 1}. p${pageIdx + 1}`;
    li.appendChild(label);

    const beatsInput = document.createElement("input");
    beatsInput.type = "number";
    beatsInput.className = "beats-input";
    beatsInput.min = "1";
    beatsInput.max = "64";
    beatsInput.title = "この区間の拍数";
    beatsInput.value = String(region.beats);
    beatsInput.addEventListener("click", (e) => e.stopPropagation());
    beatsInput.addEventListener("change", () => {
      let v = parseInt(beatsInput.value, 10);
      if (Number.isNaN(v) || v < 1) v = 1;
      region.beats = v;
      beatsInput.value = String(v);
      persist();
    });
    li.appendChild(beatsInput);

    const upBtn = document.createElement("button");
    upBtn.textContent = "↑";
    upBtn.title = "上に移動";
    upBtn.disabled = idx === 0;
    upBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      moveRegion(idx, -1);
    });
    li.appendChild(upBtn);

    const downBtn = document.createElement("button");
    downBtn.textContent = "↓";
    downBtn.title = "下に移動";
    downBtn.disabled = idx === state.regions.length - 1;
    downBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      moveRegion(idx, 1);
    });
    li.appendChild(downBtn);

    const delBtn = document.createElement("button");
    delBtn.className = "del-btn";
    delBtn.textContent = "✕";
    delBtn.title = "削除";
    delBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      deleteRegion(idx);
    });
    li.appendChild(delBtn);

    li.addEventListener("click", () => onRegionItemClick(idx));

    els.regionList.appendChild(li);
  });
}

function updateSidebarCurrent(idx) {
  els.regionList.querySelectorAll(".region-item").forEach((li) => {
    li.classList.toggle("current", Number(li.dataset.index) === idx);
  });
}

function clearHighlight() {
  regionElsById.forEach((el) => el.classList.remove("current"));
}

function highlightRegion(idx, region) {
  clearHighlight();
  const el = regionElsById.get(region.id);
  if (el) {
    el.classList.add("current");
    el.scrollIntoView({ behavior: "smooth", block: "center" });
  }
  updateSidebarCurrent(idx);
}

// --- Region editing ------------------------------------------------------

function attachDrawHandlers(wrapper, pageId) {
  let draft = null;

  wrapper.addEventListener("pointerdown", (e) => {
    if (mode !== "edit") return;
    if (e.button !== undefined && e.button !== 0) return;
    e.preventDefault();
    const rect = wrapper.getBoundingClientRect();
    const startX = e.clientX - rect.left;
    const startY = e.clientY - rect.top;
    const el = document.createElement("div");
    el.className = "region-box draft";
    wrapper.appendChild(el);
    draft = { rect, startX, startY, el };
    wrapper.setPointerCapture(e.pointerId);
  });

  wrapper.addEventListener("pointermove", (e) => {
    if (!draft) return;
    const x = e.clientX - draft.rect.left;
    const y = e.clientY - draft.rect.top;
    const left = Math.min(x, draft.startX);
    const top = Math.min(y, draft.startY);
    const w = Math.abs(x - draft.startX);
    const h = Math.abs(y - draft.startY);
    Object.assign(draft.el.style, {
      left: `${left}px`,
      top: `${top}px`,
      width: `${w}px`,
      height: `${h}px`,
    });
  });

  const finish = () => {
    if (!draft) return;
    const { rect, el } = draft;
    const w = parseFloat(el.style.width) || 0;
    const h = parseFloat(el.style.height) || 0;
    const left = parseFloat(el.style.left) || 0;
    const top = parseFloat(el.style.top) || 0;
    el.remove();
    draft = null;
    if (w < 8 || h < 8) return;
    addRegion(pageId, left / rect.width, top / rect.height, w / rect.width, h / rect.height);
  };

  wrapper.addEventListener("pointerup", finish);
  wrapper.addEventListener("pointercancel", finish);
}

function addRegion(pageId, xPct, yPct, wPct, hPct) {
  state.regions.push({ id: uid(), pageId, xPct, yPct, wPct, hPct, beats: 4 });
  renderRegionBoxes();
  renderRegionList();
  persist();
}

function moveRegion(idx, delta) {
  const newIdx = idx + delta;
  if (newIdx < 0 || newIdx >= state.regions.length) return;
  const [region] = state.regions.splice(idx, 1);
  state.regions.splice(newIdx, 0, region);
  renderRegionBoxes();
  renderRegionList();
  persist();
}

function deleteRegion(idx) {
  state.regions.splice(idx, 1);
  renderRegionBoxes();
  renderRegionList();
  persist();
}

function onRegionItemClick(idx) {
  const region = state.regions[idx];
  if (!region) return;
  pendingStartIndex = idx;
  highlightRegion(idx, region);
  if (mode === "play" && playback.playing) {
    playback.start(beatsBeforeIndex(idx));
  }
}

// --- Mode / playback controls --------------------------------------------

function setMode(newMode) {
  mode = newMode;
  document.body.classList.toggle("mode-edit", mode === "edit");
  document.body.classList.toggle("mode-play", mode === "play");
  els.modeEditBtn.classList.toggle("active", mode === "edit");
  els.modePlayBtn.classList.toggle("active", mode === "play");

  if (mode === "edit") {
    playback.stop();
    updatePlayButton(false);
    clearHighlight();
  }
}

function updatePlayButton(playing) {
  els.playBtn.textContent = playing ? "⏸ 一時停止" : "▶ 再生";
  els.playBtn.classList.toggle("active", playing);
}

function bumpBpm(delta) {
  state.bpm = Math.max(20, Math.min(300, state.bpm + delta));
  els.bpmInput.value = String(state.bpm);
  persist();
}

// --- Import / export -------------------------------------------------------

async function handleFiles(files) {
  showToast("取り込み中…");
  let failures = 0;
  for (const file of files) {
    try {
      const isPdf = file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf");
      if (isPdf) {
        const images = await pdfFileToImages(file);
        images.forEach((img) => state.pages.push({ id: uid(), ...img }));
      } else if (file.type.startsWith("image/")) {
        const img = await imageFileToImage(file);
        state.pages.push({ id: uid(), ...img });
      }
    } catch (err) {
      console.error(err);
      failures += 1;
    }
  }
  renderPages();
  persist();
  showToast(failures ? `一部のファイルの取り込みに失敗しました（${failures}件）` : "取り込み完了");
}

// --- Event bindings --------------------------------------------------------

function bindEvents() {
  els.modeEditBtn.addEventListener("click", () => setMode("edit"));
  els.modePlayBtn.addEventListener("click", () => setMode("play"));

  els.fileInput.addEventListener("change", (e) => {
    const files = Array.from(e.target.files || []);
    e.target.value = "";
    if (files.length) handleFiles(files);
  });

  els.exportBtn.addEventListener("click", () => exportProjectFile(state));

  els.importInput.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    e.target.value = "";
    if (!file) return;
    try {
      const data = await importProjectFile(file);
      state = { ...defaultState(), ...data };
      playback.stop();
      pendingStartIndex = 0;
      renderAll();
      persist();
      showToast("読み込みました");
    } catch (err) {
      console.error(err);
      showToast("読み込みに失敗しました（不正なファイル）");
    }
  });

  els.clearBtn.addEventListener("click", () => {
    if (!confirm("すべてのページと区間マークを削除します。よろしいですか？")) return;
    playback.stop();
    updatePlayButton(false);
    pendingStartIndex = 0;
    state = { ...defaultState(), bpm: state.bpm, loop: state.loop, metronomeOn: state.metronomeOn };
    clearStoredProject();
    renderAll();
  });

  els.bpmInput.addEventListener("change", () => {
    let v = parseInt(els.bpmInput.value, 10);
    if (Number.isNaN(v)) v = 90;
    v = Math.max(20, Math.min(300, v));
    els.bpmInput.value = String(v);
    state.bpm = v;
    persist();
  });
  els.bpmUp.addEventListener("click", () => bumpBpm(1));
  els.bpmDown.addEventListener("click", () => bumpBpm(-1));

  els.tapTempoBtn.addEventListener("click", () => {
    const now = performance.now();
    tapTimes.push(now);
    tapTimes = tapTimes.filter((t) => now - t < 3000);
    if (tapTimes.length >= 2) {
      const intervals = [];
      for (let i = 1; i < tapTimes.length; i++) intervals.push(tapTimes[i] - tapTimes[i - 1]);
      const avgMs = intervals.reduce((a, b) => a + b, 0) / intervals.length;
      state.bpm = Math.max(20, Math.min(300, Math.round(60000 / avgMs)));
      els.bpmInput.value = String(state.bpm);
      persist();
    }
  });

  els.loopToggle.addEventListener("change", () => {
    state.loop = els.loopToggle.checked;
    persist();
  });
  els.metronomeToggle.addEventListener("change", () => {
    state.metronomeOn = els.metronomeToggle.checked;
    persist();
  });

  els.playBtn.addEventListener("click", () => {
    if (playback.playing) {
      playback.stop();
      updatePlayButton(false);
      return;
    }
    if (!state.regions.length) {
      showToast("区間が登録されていません。編集モードでマークしてください。");
      return;
    }
    playback.start(beatsBeforeIndex(pendingStartIndex));
    updatePlayButton(true);
  });

  els.stopBtn.addEventListener("click", () => {
    playback.stop();
    pendingStartIndex = 0;
    clearHighlight();
    updateSidebarCurrent(-1);
    updatePlayButton(false);
  });

  els.sidebarToggleBtn.addEventListener("click", () => {
    sidebarOpen = !sidebarOpen;
    els.sidebar.classList.toggle("hidden", !sidebarOpen);
  });
  els.sidebarCloseBtn.addEventListener("click", () => {
    sidebarOpen = false;
    els.sidebar.classList.add("hidden");
  });
}

// --- Init --------------------------------------------------------------

function init() {
  const saved = loadProject();
  if (saved) state = { ...defaultState(), ...saved };
  renderAll();
  bindEvents();
  setMode("edit");
}

init();
