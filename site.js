// Client logo strip: turn the static list into a seamless infinite marquee (skipped for reduced motion)
(function(){
  var list = document.querySelector('.clients');
  if(!list) return;
  if(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var viewport = document.createElement('div');
  viewport.className = 'clients-marquee';
  if(list.hasAttribute('data-reveal')){
    viewport.setAttribute('data-reveal', '');
    list.removeAttribute('data-reveal');
  }
  var track = document.createElement('div');
  track.className = 'clients-track';
  list.parentNode.insertBefore(viewport, list);
  viewport.appendChild(track);
  track.appendChild(list);
  for(var i = 0; i < 3; i++){
    var copy = list.cloneNode(true);
    copy.setAttribute('aria-hidden', 'true');
    copy.querySelectorAll('img').forEach(function(img){ img.alt = ''; img.removeAttribute('loading'); });
    track.appendChild(copy);
  }
})();
(function(){
  var toggle = document.getElementById('menuToggle');
  var nav = document.getElementById('navlinks');
  if(toggle && nav){
    toggle.addEventListener('click', function(){
      var open = nav.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    nav.querySelectorAll('a').forEach(function(a){
      a.addEventListener('click', function(){
        nav.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  // Scroll/load reveal for [data-reveal] elements (hero copy + floating status chips)
  var revealEls = document.querySelectorAll('[data-reveal]');
  if(revealEls.length){
    if('IntersectionObserver' in window){
      var io = new IntersectionObserver(function(entries){
        entries.forEach(function(entry){
          if(entry.isIntersecting){
            entry.target.classList.add('in-view');
            io.unobserve(entry.target);
          }
        });
      }, { threshold:.15, rootMargin:'0px 0px -40px 0px' });
      revealEls.forEach(function(el){ io.observe(el); });
    } else {
      revealEls.forEach(function(el){ el.classList.add('in-view'); });
    }
    // Safety net: never leave content stuck invisible
    setTimeout(function(){
      revealEls.forEach(function(el){ el.classList.add('in-view'); });
    }, 1800);
  }
})();
(function(){
    var canHover = window.matchMedia && window.matchMedia('(hover:hover) and (pointer:fine)').matches;
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (!canHover || reduceMotion) return;

    document.body.classList.add('has-custom-cursor');

    var dot = document.createElement('div');
    dot.className = 'cursor-dot';
    var ring = document.createElement('div');
    ring.className = 'cursor-ring';
    document.body.appendChild(ring);
    document.body.appendChild(dot);

    var mouseX = window.innerWidth / 2, mouseY = window.innerHeight / 2;
    var ringX = mouseX, ringY = mouseY;

    window.addEventListener('mousemove', function(e){
      mouseX = e.clientX;
      mouseY = e.clientY;
      dot.style.transform = 'translate(' + mouseX + 'px,' + mouseY + 'px) translate(-50%,-50%)';
    });

    function tick(){
      ringX += (mouseX - ringX) * 0.18;
      ringY += (mouseY - ringY) * 0.18;
      ring.style.transform = 'translate(' + ringX + 'px,' + ringY + 'px) translate(-50%,-50%)';
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);

    var hoverSelector = 'a, button, .btn, input, textarea';
    document.addEventListener('mouseover', function(e){
      if (e.target.closest(hoverSelector)) ring.classList.add('is-hover');
    });
    document.addEventListener('mouseout', function(e){
      if (e.target.closest(hoverSelector)) ring.classList.remove('is-hover');
    });

    document.addEventListener('mouseleave', function(){
      dot.style.opacity = '0';
      ring.style.opacity = '0';
    });
    document.addEventListener('mouseenter', function(){
      dot.style.opacity = '1';
      ring.style.opacity = '';
    });
  })();

(function(){
    var canHover = window.matchMedia && window.matchMedia('(hover:hover) and (pointer:fine)').matches;
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (!canHover || reduceMotion) return;

    var strength = 0.35;
    document.querySelectorAll('.btn').forEach(function(btn){
      btn.addEventListener('mousemove', function(e){
        var r = btn.getBoundingClientRect();
        var x = e.clientX - r.left - r.width / 2;
        var y = e.clientY - r.top - r.height / 2;
        btn.style.transform = 'translate(' + (x * strength) + 'px,' + (y * strength) + 'px)';
      });
      btn.addEventListener('mouseleave', function(){
        btn.style.transform = 'translate(0,0)';
      });
    });
  })();

(function(){
    var els = document.querySelectorAll('.count-up');
    if (!els.length) return;
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function animate(el){
      var target = parseFloat(el.getAttribute('data-count-to'));
      if (reduceMotion || !('requestAnimationFrame' in window)){
        el.textContent = target;
        return;
      }
      var duration = 2600;
      var start = null;
      function step(ts){
        if (start === null) start = ts;
        var progress = Math.min((ts - start) / duration, 1);
        var eased = 1 - Math.pow(1 - progress, 2);
        el.textContent = Math.round(target * eased);
        if (progress < 1) requestAnimationFrame(step);
        else el.textContent = target;
      }
      requestAnimationFrame(step);
    }

    if ('IntersectionObserver' in window){
      var io = new IntersectionObserver(function(entries){
        entries.forEach(function(entry){
          if (entry.isIntersecting){
            animate(entry.target);
            io.unobserve(entry.target);
          }
        });
      }, {threshold:.6});
      els.forEach(function(el){ io.observe(el); });
    } else {
      els.forEach(animate);
    }
  })();

