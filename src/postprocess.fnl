(local {: highlight-code-block} (require :code))
(local {: split-ext} (require :fs))

(λ replace-img-dirs [html-content new-dir]
  (html-content:gsub "%%%%DIR%%%%" (.. "/" new-dir)))

(λ replace-img-bodies [html-content]
  (fn handle-equation [start title end]
    (.. start title end))

  (fn handle-image [start title end]
    (let [newstart (string.format "<div class=\"img-cont\">%s" start)
          newend (string.format "title=\"%s\"%s<p class=\"img-caption\"><i>%s</i></p></div>"
                                title end title)]
      (.. newstart newend)))

  (fn handle-video [src ext title props]
    (let [new-props (props:gsub "/>" ">")
          newstart (string.format "<div class=\"img-cont\"><video controls loop %s"
                                  new-props)
          newmiddle (string.format "<source src=\"%s\" type=\"video/%s\">" src
                                   ext)
          newend (string.format "</video><p class=\"img-caption\"><i>%s</i></div>"
                                title)]
      (.. newstart newmiddle newend)))

  (fn video? [ext]
    (or (= ext "mp4") (= ext "webm")))

  (fn do-thing [start title end]
    (let [src (start:match "src=\"([^\"]*)\"")
          (_file ext) (split-ext src)]
      (if (title:match "Equation%s%d") (handle-equation start title end)
          (video? ext) (handle-video src ext title end)
          (handle-image start title end))))

  (html-content:gsub "(%<img%s-[^%>]*)title=\"([^\"]*)\"([^%>]*/%>)" do-thing))

(λ sanitize-code-blocks [html-content]
  html-content)

; (let [replaced-code-start (html-content:gsub "<code>u"
;                                              "<div class=\"code-block\"><pre><code>")
;       replaced-code (replaced-code-start:gsub "</code>" "</code></pre></div>")]
;   (replaced-code:gsub "%<code%>(.-)\n(.[^%>]*)%s?%</code%>"
;                       highlight-code-block)))

{: replace-img-dirs : replace-img-bodies : sanitize-code-blocks}
