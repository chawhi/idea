const STORAGE_KEY = "sheet-markup-project-v1";

export function loadProject() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (err) {
    console.warn("Failed to load saved project", err);
    return null;
  }
}

export function saveProject(project) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(project));
    return true;
  } catch (err) {
    console.warn("Failed to save project (storage quota?)", err);
    return false;
  }
}

export function clearStoredProject() {
  localStorage.removeItem(STORAGE_KEY);
}

export function exportProjectFile(project) {
  const blob = new Blob([JSON.stringify(project)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
  const a = document.createElement("a");
  a.href = url;
  a.download = `sheet-markup-${stamp}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

export function importProjectFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        resolve(JSON.parse(reader.result));
      } catch (err) {
        reject(err);
      }
    };
    reader.onerror = reject;
    reader.readAsText(file);
  });
}
