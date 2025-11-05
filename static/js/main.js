"use strict";

import { rollFunnyImage, roll404 } from "./random.js";
import { fetchMoeCounter, fetchNeocitiesMeta } from "./meta.js";

function populateRandomImage() {
  const img_elem = document.getElementById("random-image");
  const caption_elem = document.getElementById("random-image-caption");
  if (!img_elem || !caption_elem) {
    return;
  }

  const { src, caption } = rollFunnyImage();
  img_elem.src = src;
  caption_elem.innerHTML = caption;
}

function populateCounter() {
  const moe_counter = document.getElementById("moe-counter");
  if (!moe_counter) {
    return;
  }
  const onError = (err) => {
    console.log(`ERROR @ populateCounter(): ${err}`);
    moe_counter.innerHTML = fetchMoeCounter(0);
    moe_counter.innerHTML += `<p>Failed to fetch visits from Neocities API. Using Moe Counter fallback.`;
  };
  fetchNeocitiesMeta().then((info) => {
    if (info.error) {
      onError(info.error);
      return;
    }
    const views = parseInt(info.views);
    if (Number.isNaN(views)) {
      onError("Failed to parse views");
      return;
    }
    moe_counter.innerHTML = fetchMoeCounter(views);
  })
}

function randomize404() {
  const img = document.getElementById("404-image");
  if (!img) {
    return;
  }
  const { src } = roll404();
  img.src = src;
}

(function(){
  populateRandomImage();
  populateCounter();
  randomize404();
})();
