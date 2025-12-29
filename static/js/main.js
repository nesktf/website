"use strict";

import { Mustache } from "./modules/mustache.js"
import { fetchMoeCounter, fetchNeocitiesMeta, fetchBlogEntries } from "./modules/api.js";

function rollArrayItem(array) {
  return array[Math.floor(Math.random()*array.length)];
}

function populateRandomImage() {
  const FUNNY_IMAGE_SET = [
    ["kyouko_pc.png", "Kyouko browsing the <a href=\"/blog\">blog</a>"],
    ["mari_emacs.png", "Shoutouts to witchmacs"],
    ["keiki_hello.gif", "Keiki is happy to see you here!!"],
    ["cirno_cpp.png", "The smartest will teach you!"],
    ["chen.png", "Chen is here too!"],
    ["flani_reimu.png", "Time, Dr. Freeman?"]
  ];

  const img_elem = document.getElementById("random-image");
  const caption_elem = document.getElementById("random-image-caption");
  if (!img_elem || !caption_elem) {
    return;
  }

  const [image, caption] = rollArrayItem(FUNNY_IMAGE_SET);
  img_elem.src = `/image/funnies/${image}`;
  caption_elem.innerHTML = caption;
}

function randomize404() {
  const NOT_FOUND_IMAGE_SET = [
    "404_marisad.png",
    "404_cino.png",
    "404_kogasa.png",
    "404_okina.png",
  ];

  const img = document.getElementById("404-image");
  if (!img) {
    return;
  }
  const image = rollArrayItem(NOT_FOUND_IMAGE_SET);
  img.src = `/image/funnies/${image}`;
}

async function searchBlog() {
  const entries = await fetchBlogEntries();
  const templ = document.getElementById("templ-blog-entry").innerHTML;
  const input = document.getElementById("blog-search-input");
  const elem = document.getElementById("blog-entries");

  const renderEntries = (entries) => {
    if (entries.length === 0) {
      return "<p>Nothing found :(</p>"
    }
    return Mustache.render(templ, {entries});
  }

  const onSearch = (str) => {
    const filtered = str === "" ? entries : entries.filter((entry) => {
      return entry.name.toLowerCase().includes(str.toLowerCase());
    })
    elem.innerHTML = renderEntries(filtered.map((entry) => {
      return {
        name: entry.name,
        url: entry.url,
        date: new Date(parseInt(entry.date)).toISOString(),
      }
    }));
  };

  onSearch("");
  input.addEventListener("input", async (ev) => {
    const str = ev.target.value;
    onSearch(str);
  });
}

async function populateCounter() {
  const counter = document.getElementById("moe-counter");

  const onError = (err) => {
    console.log(`ERROR @ populateCounter(): ${err}`);
    counter.innerHTML = fetchMoeCounter(0);
    counter.innerHTML += `<p>Failed to fetch visits from Neocities API. Using Moe Counter fallback.`;
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
    counter.innerHTML = fetchMoeCounter(views);
  })
}

export default async function main(page_name) {
  const PAGE_CALLBACKS = new Map([
    ["index", populateCounter],
    ["not-found", randomize404],
    ["blog", searchBlog],
  ])
  populateRandomImage();
  randomize404();
  const callback = PAGE_CALLBACKS.get(page_name);
  if (callback) {
    callback();
  }
}
