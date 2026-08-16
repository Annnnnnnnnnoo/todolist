const STORAGE_KEY = "todolist.items";

// 数据结构：{ id, text, done }
let items = load();

const form = document.getElementById("add-form");
const input = document.getElementById("add-input");
const list = document.getElementById("list");
const empty = document.getElementById("empty");
const count = document.getElementById("count");
const closeBtn = document.getElementById("close");

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
}

function render() {
  list.innerHTML = "";
  const active = items.filter((i) => !i.done).length;
  count.textContent = `${active}/${items.length}`;
  empty.style.display = items.length ? "none" : "block";

  for (const item of items) {
    const li = document.createElement("li");
    li.className = "item" + (item.done ? " item--done" : "");
    li.draggable = true;
    li.dataset.id = item.id;

    const check = document.createElement("button");
    check.className = "item__check";
    check.textContent = "✓";
    check.setAttribute("aria-label", "标记完成");
    check.addEventListener("click", () => toggle(item.id));

    const text = document.createElement("span");
    text.className = "item__text";
    text.textContent = item.text;

    const del = document.createElement("button");
    del.className = "item__del";
    del.textContent = "×";
    del.setAttribute("aria-label", "删除");
    del.addEventListener("click", () => remove(item.id));

    li.append(check, text, del);

    // 拖动排序：HTML5 原生拖拽
    li.addEventListener("dragstart", (e) => {
      dragId = item.id;
      li.classList.add("is-dragging");
      e.dataTransfer.effectAllowed = "move";
      // Firefox 需要设置 data 才能正常触发 dragover
      e.dataTransfer.setData("text/plain", item.id);
    });

    li.addEventListener("dragend", () => {
      dragId = null;
      clearDropIndicator();
    });

    li.addEventListener("dragover", (e) => {
      if (!dragId || dragId === item.id) return;
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      const rect = li.getBoundingClientRect();
      const before = e.clientY < rect.top + rect.height / 2;
      li.classList.toggle("drop-before", before);
      li.classList.toggle("drop-after", !before);
    });

    li.addEventListener("dragleave", () => {
      li.classList.remove("drop-before", "drop-after");
    });

    li.addEventListener("drop", (e) => {
      e.preventDefault();
      if (!dragId || dragId === item.id) return;
      const rect = li.getBoundingClientRect();
      const before = e.clientY < rect.top + rect.height / 2;
      reorder(dragId, item.id, before);
    });

    list.appendChild(li);
  }
}

// ===== 拖动排序状态 =====
let dragId = null;

function clearDropIndicator() {
  list.querySelectorAll(".drop-before, .drop-after").forEach((el) =>
    el.classList.remove("drop-before", "drop-after")
  );
}

function reorder(fromId, targetId, before) {
  const from = items.findIndex((i) => i.id === fromId);
  if (from < 0) return;
  const [moved] = items.splice(from, 1);
  const to = items.findIndex((i) => i.id === targetId);
  if (to < 0) {
    items.splice(from, 0, moved); // 目标异常，还原
    return;
  }
  items.splice(before ? to : to + 1, 0, moved);
  save();
  render();
}

function add(text) {
  const t = text.trim();
  if (!t) return;
  const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  items.unshift({ id, text: t, done: false });
  save();
  render();
}

function toggle(id) {
  const item = items.find((i) => i.id === id);
  if (item) {
    item.done = !item.done;
    save();
    render();
  }
}

function remove(id) {
  items = items.filter((i) => i.id !== id);
  save();
  render();
}

// 关闭按钮：调用 Rust 侧 quit 退出应用
closeBtn.addEventListener("click", () => {
  const invoke = window.__TAURI__?.core?.invoke;
  if (invoke) invoke("quit");
  else window.close();
});

form.addEventListener("submit", (e) => {
  e.preventDefault();
  add(input.value);
  input.value = "";
  input.focus();
});

render();
input.focus();
