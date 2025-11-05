"use strict";

const FUNNY_IMAGE_SET = [
  ["kyouko_pc.png", "Kyouko browsing the <a href=\"/blog\">blog</a>"],
  ["mari_emacs.png", "Shoutouts to witchmacs"],
  ["keiki_hello.gif", "Keiki is happy to see you here!!"],
  ["cirno_cpp.png", "The smartest will teach you!"],
  ["chen.png", "Chen is here too!"],
];

function rollArrayItem(array) {
  return array[Math.floor(Math.random()*array.length)];
}

export function rollFunnyImage() {
  const [image, caption] = rollArrayItem(FUNNY_IMAGE_SET);
  return { src: `/image/funnies/${image}`, caption };
}

const NOT_FOUND_IMAGE_SET = [
  "404_marisad.png",
  "404_cino.png",
  "404_kogasa.png",
  "404_okina.png",
]

export function roll404() {
  const image = rollArrayItem(NOT_FOUND_IMAGE_SET);
  return { src: `/image/funnies/${image}` };
}
