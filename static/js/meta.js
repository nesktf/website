"use strict";

const moe_name = "test123444"; // lol
const moe_theme = "booru-jaypee";

export function fetchMoeCounter(count) {
  const url = `https://count.getloli.com/@${moe_name}?name=${moe_name}&theme=${moe_theme}&padding=7&offset=0&align=center&scale=1&pixelated=0&darkmode=0&num=${count}`;
  return `<img src="${url}" alt="moe_counter" />`;
};

export async function fetchNeocitiesMeta() {
  return fetch("https://neocities.org/api/info?sitename=nesktf")
  .then(async (res) => {
    if (!res.ok) {
      return { error: "Fetch failied" };
    }
    const json = await res.json();
    if (json.result != "success") {
      return { error: "Neocities API error" };
    }
    return json.info;
  })
  .catch((err) => {
    return { error: err }
  })
};

export async function fetchBlogEntries() {
  return fetch("/api/blog.json")
  .then(async (res) => {
    if (!res.ok) {
      return [];
    }
    return await res.json();
  });
}

export async function fetchProjectEntries() {
  return fetch("/api/projects.json")
  .then(async (res) => {
    if (!res.ok) {
      return [];
    }
    return await res.json();
  });
}
