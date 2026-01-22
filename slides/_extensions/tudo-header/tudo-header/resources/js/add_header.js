function header() {
  function add_header() {
    let header = document.querySelector("div.reveal-header");
    let reveal = document.querySelector(".reveal");
    reveal.insertBefore(header, reveal.firstChild);
    
    let logo_img = document.querySelector('.header-logo img');
    if (logo_img?.getAttribute('src') == null) {
      if (logo_img?.getAttribute('data-src') != null) {
        logo_img.src = logo_img?.getAttribute('data-src') || "";
        logo_img?.removeAttribute('data-src'); 
      };
    };
    
    let logo_img_right = document.querySelector('.header-logo-right img');
    if (logo_img_right?.getAttribute('src') == null && logo_img_right?.getAttribute('data-src') != null) {
      logo_img_right.src = logo_img_right.getAttribute('data-src');
      logo_img_right.removeAttribute('data-src');
    }
  };
  
  function change_header(dheader, cheader, ctext) {
    if (dheader !== null) {
      cheader.innerHTML = dheader.innerHTML;  
    } else {
      cheader.innerHTML = ctext;
    };
  };
  
  if (Reveal.isReady()) {
    add_header();
    
    if (document.querySelector('div.reveal.has-logo') != null) {
      var slide_number = document.querySelector('div.slide-number');
      var header = document.querySelector("div.reveal-header");
      header.appendChild(slide_number);
    };
      
    var header_text = document.querySelector("div.header-text p");
    const header_inner_html = header_text.innerHTML;
    
    document.querySelectorAll('div.header').forEach(el => {
      el.style.display = 'none';
    });
    
    let dynamic_header = Reveal.getCurrentSlide().querySelector('div.header p');
    change_header(dynamic_header, header_text, header_inner_html);
    
    Reveal.on('slidechanged', event => {
      let dyn_header = event.currentSlide.querySelector('div.header p');
      change_header(dyn_header, header_text, header_inner_html);
    });
  }; 
};


window.addEventListener("load", (event) => {
  header();
});
