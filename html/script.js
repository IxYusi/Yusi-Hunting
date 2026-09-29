const panel = document.getElementById('mission');
const title = document.getElementById('title');
const time = document.getElementById('time');
const fill = document.getElementById('fill');
const rows = document.getElementById('rows');

let timer = null;

function pad(n) {
    return String(n).padStart(2, '0');
}

function start(duration) {
    const total = duration * 1000;
    const end = Date.now() + total;

    clearInterval(timer);

    const tick = () => {
        const left = Math.max(0, end - Date.now());
        const secs = Math.ceil(left / 1000);

        time.textContent = `${pad(Math.floor(secs / 60))}:${pad(secs % 60)}`;
        fill.style.width = `${(left / total) * 100}%`;
        panel.classList.toggle('low', secs <= 300);

        if (left <= 0) clearInterval(timer);
    };

    tick();
    timer = setInterval(tick, 250);
}

function show(data) {
    title.textContent = data.title;
    rows.innerHTML = '';

    (data.rows || []).forEach((row) => {
        const li = document.createElement('li');
        const name = document.createElement('span');
        const amount = document.createElement('span');

        name.textContent = row.label;
        amount.textContent = row.amount || '';
        li.append(name, amount);
        rows.appendChild(li);
    });

    start(data.duration);
    panel.classList.remove('hidden');
}

function hide() {
    clearInterval(timer);
    panel.classList.add('hidden');
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'show') show(data);
    else if (data.action === 'hide') hide();
});
