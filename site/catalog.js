(async () => {
  const $ = id => document.getElementById(id);
  const grid = $("grid");
  const qEl = $("q");
  const kindEl = $("kind-filter");
  const osEl = $("os-filter");
  const countEl = $("count");

  // Resolve the JSON path relative to the page. Strip a trailing /site/ so that
  // serving the repo checkout directly (e.g. `python3 -m http.server` from the root)
  // resolves to /json/index.json rather than /site/json/index.json.
  const raw = location.pathname.endsWith("/") ? location.pathname : location.pathname.replace(/\/[^/]*$/, "/");
  const base = (raw.endsWith("/site/") ? raw.slice(0, -5) : raw) || "/";
  const jsonUrl = new URL("json/index.json", new URL(base, location.href)).href;

  let scripts = [];
  try {
    const res = await fetch(jsonUrl, { cache: "no-cache" });
    if (!res.ok) throw new Error(`HTTP ${res.status} loading catalog`);
    ({ scripts } = await res.json());
  } catch (e) {
    grid.innerHTML = `<p class="empty">Could not load catalog: ${esc(String(e))}</p>`;
    return;
  }

  // Populate OS filter
  const oses = [...new Set(scripts.map(s => s.var_os).filter(Boolean))].sort();
  oses.forEach(o => osEl.add(new Option(o, o)));

  const render = () => {
    const term = qEl.value.trim().toLowerCase();
    const kind = kindEl.value;
    const os = osEl.value;

    const visible = scripts.filter(s => {
      if (kind && s.kind !== kind) return false;
      if (os && s.var_os !== os) return false;
      if (term) {
        const haystack = [s.name, s.slug, s.var_tags || "", s.var_os || ""]
          .join(" ").toLowerCase();
        if (!haystack.includes(term)) return false;
      }
      return true;
    });

    countEl.textContent = `${visible.length} of ${scripts.length} scripts`;

    if (visible.length === 0) {
      grid.innerHTML = `<p class="empty">No scripts match your filters.</p>`;
      return;
    }

    grid.innerHTML = "";
    visible.forEach(s => grid.appendChild(buildCard(s)));
  };

  [qEl, kindEl, osEl].forEach(el => el.addEventListener("input", render));
  render();

  function buildCard(s) {
    const el = document.createElement("div");
    el.className = "card";

    const tags = (s.var_tags || "").split(/[;,\s]+/).filter(Boolean);
    const cpu = esc(s.var_cpu || "?");
    const ram = esc(s.var_ram ? `${s.var_ram}MB` : "?");
    const disk = esc(s.var_disk ? `${s.var_disk}GB` : "?");
    const os = [s.var_os, s.var_version].filter(Boolean).join(" ");
    const cardId = `cmd-${esc(s.slug)}`;

    const linksHtml = (s.source && /^https?:\/\//i.test(s.source))
      ? `<div class="links"><a href="${esc(s.source)}" target="_blank" rel="noopener">upstream source ↗</a></div>`
      : "";

    el.innerHTML = `
      <div class="card-header">
        <h3 class="card-name">${esc(s.name)}</h3>
        <span class="kind-badge">${esc(s.kind)}</span>
      </div>
      <div class="resources">${esc(os)} · ${cpu}c / ${ram} RAM / ${disk} disk</div>
      ${tags.length ? `<div class="tags">${tags.map(t => `<span class="tag">${esc(t)}</span>`).join("")}</div>` : ""}
      ${linksHtml}
      <div class="cmd-row">
        <div class="cmd-box" id="${cardId}">${esc(s.install_command)}</div>
        <button class="copy-btn">Copy</button>
      </div>
    `;
    el.querySelector('.copy-btn').addEventListener('click', function() {
      const text = el.querySelector('.cmd-box')?.textContent ?? "";
      if (!navigator.clipboard) {
        this.textContent = "Copy unavailable";
        setTimeout(() => { this.textContent = "Copy"; }, 2000);
        return;
      }
      navigator.clipboard.writeText(text).then(() => {
        const orig = this.textContent;
        this.textContent = "Copied!";
        setTimeout(() => { this.textContent = orig; }, 1500);
      }).catch(() => {
        const orig = this.textContent;
        this.textContent = "Copy failed";
        setTimeout(() => { this.textContent = orig; }, 2000);
      });
    });
    return el;
  }

  function esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[c]));
  }
})();
