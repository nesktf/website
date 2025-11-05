(local {: highlight-code-block} (require :code))

(λ replace-img-dirs [html-content new-dir]
  (html-content:gsub "%%%%DIR%%%%" (.. "/" new-dir)))

(λ replace-img-bodies [html-content]
  (fn do-thing [start title end]
    (if (title:match "Equation%s%d")
        (.. start title end)
        (let [newstart (string.format "<div class=\"img-cont\">%s" start)
              newend (string.format "title=\"%s\"%s<p class=\"img-caption\"><i>%s</i></p></div>"
                                    title end title)]
          (.. newstart newend))))

  (html-content:gsub "(%<img%s-[^%>]*)title=\"([^\"]*)\"([^%>]*/%>)" do-thing))

(λ sanitize-code-blocks [html-content]
  html-content)

; (let [replaced-code-start (html-content:gsub "<code>u"
;                                              "<div class=\"code-block\"><pre><code>")
;       replaced-code (replaced-code-start:gsub "</code>" "</code></pre></div>")]
;   (replaced-code:gsub "%<code%>(.-)\n(.[^%>]*)%s?%</code%>"
;                       highlight-code-block)))

{: replace-img-dirs : replace-img-bodies : sanitize-code-blocks}
