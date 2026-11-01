// Hero wall: Cyllene's app list on the real fleet (the apps' own icons). Each platform walks through App Store
// Connect's states the way a release does, and the dot changes colour with it.
(function () {
  var wall = document.getElementById('fwall'); if (!wall) return;
  var still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var n = innerWidth <= 560 ? 6 : innerWidth <= 900 ? 8 : 12;
  var APPS = [['Airwell', 'airwell', '2.1.0'], ['Blackcomb', 'blackcomb', '1.0.0'], ['Bugle News', 'bugle', '6.1.0'], ['Echo', 'echo', '3.0.0'],
              ['Elah', 'elah', '2.1.0'], ['Epiphany', 'epiphany', '6.3.0'], ['Kernel', 'kernel', '20.0.1'], ['Melete', 'melete', '3.2.0'],
              ['Pan', 'pan', '4.0.0'], ['Patois', 'patois', '1.1.5'], ['Scrounger', 'scrounger', '1.0.0'], ['Talli', 'talli', '5.0.0']];
  var STATES = [['Prepare for Submission', '#8e8e93'], ['Waiting for Review', '#d99a00'], ['In Review', '#0847c4'], ['Pending Release', '#2a9d8f'], ['Ready for Sale', '#22a35a']];
  var el = function (t, c, x) { var e = document.createElement(t); if (c) e.className = c; if (x != null) e.textContent = x; return e; };
  var wait = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };
  for (var i = 0; i < n; i++) (function (app, i) {
    var a = wall.appendChild(el('div', 'fc')), img = a.appendChild(el('img'));
    img.src = 'fleet/' + app[1] + '.svg'; img.alt = ''; a.appendChild(el('b', '', app[0]));
    var rows = ['iOS', 'macOS'].map(function (plat, j) {
      var p = a.appendChild(el('p')); p.appendChild(el('i')); p.appendChild(el('span', '', app[2] + ' on ' + plat)); var em = p.appendChild(el('em'));
      return { p: p, em: em, s: (i * 2 + j * 3) % STATES.length };
    });
    function show(r, flip) {
      var st = STATES[r.s]; r.em.textContent = st[0]; r.p.style.setProperty('--c', st[1]);
      if (flip) { r.p.classList.remove('flip'); void r.p.offsetWidth; r.p.classList.add('flip'); }
    }
    rows.forEach(function (r) { show(r); });
    if (still) return;
    (function loop(j) {
      wait(2600 + ((i * 37) % 9) * 300).then(function () { var r = rows[j % 2]; r.s = (r.s + 1) % STATES.length; show(r, true); loop(j + 1); });
    })(i);
  })(APPS[i % APPS.length], i);
})();

// Hero parallax: the wall drifts at 0.45, the copy lifts at 0.2 and fades. Off under reduced motion.
(function () {
  var bg = document.querySelector('.hero-bg'), copy = document.querySelector('.hero-copy');
  if (!bg || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var t = 0;
  addEventListener('scroll', function () {
    if (t) return;
    t = requestAnimationFrame(function () {
      t = 0; var y = scrollY, h = innerHeight; if (y > h * 1.2) return;
      bg.style.setProperty('--py', (y * .45) + 'px');
      copy.style.transform = 'translate3d(0,' + (y * .2) + 'px,0)'; copy.style.opacity = Math.max(0, 1 - y / (h * .7));
    });
  }, { passive: true });
})();
