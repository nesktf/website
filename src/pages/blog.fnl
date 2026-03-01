(local {: cat/ : split-ext} (require :util))
(local {: file-op} (require :fs))
(local {: tex-compile : html-highlight-code} (require :compiler))

(λ blog-links [entries]
  "Get blog links with format `{:name <string> :url <string> :date <epoch> :tags <string[]>}`"
  ;; From newest to oldest
  (table.sort entries (fn [entry-a entry-b]
                        (let [date-a (tonumber entry-a.date)
                              date-b (tonumber entry-b.date)]
                          (> date-a date-b))))
  (icollect [_i entry (ipairs entries)]
    {:name entry.name
     :url (string.format "/blog/%s" entry.id)
     :subtitle entry.subtitle
     :date entry.date
     :tags entry.tags}))

(λ blog-post [content id]
  "Do post processing on a blog entry. Returns new content."
  (fn replace-img-dirs [html-content new-dir]
    (html-content:gsub "%%%%DIR%%%%" (.. "/" new-dir)))

  (fn replace-img-bodies [html-content]
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
            newmiddle (string.format "<source src=\"%s\" type=\"video/%s\">"
                                     src ext)
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

  (let [entry-path (cat/ "blog" id)
        img-dirs (replace-img-dirs content entry-path)
        img-bodies (replace-img-bodies img-dirs)]
    img-bodies))

(λ blog-pre [content files paths]
  "Do pre processing on a blog entry. Returns new content"
  (fn inject-latex [md-content]
    (var eq-id 1)

    (fn make-tag [inline? src alt title]
      (if inline?
          ;; No title in inline blocks
          (string.format "<img class=\"tex-image-inline\"
                               src=\"%%%%DIR%%%%/%s\"
                               alt=\"%s\" />" src alt)
          (string.format "<div class=\"tex-image-cont\">
                            <img class=\"tex-image-block\"
                                 src=\"%%%%DIR%%%%/%s\"
                                 alt=\"%s\"
                                 title=\"%s\" />
                          </div>" src alt title)))

    (fn replace-eq [matched inline?]
      (let [{: equation : image} (tex-compile paths.cache matched inline?)
            image-file (string.format "eq_%d.svg" eq-id)
            img-tag (make-tag inline? image-file equation
                              (string.format "Equation %d" eq-id))]
        (table.insert files {:op file-op.write :content image :name image-file})
        (set eq-id (+ eq-id 1))
        img-tag))

    ;; Replace equation blocks ($$ $$) and then inline equations ($ $)
    (let [first-replace (md-content:gsub "%$%$(.-)%$%$" #(replace-eq $1 false))]
      (first-replace:gsub "%$(.-)%$" #(replace-eq $1 true))))

  (fn highlight-code [md-content]
    (md-content:gsub "```([^%s]*)%s([^%`]*)```"
                     #(html-highlight-code paths.script paths.cache $1 $2)))

  (-> content (inject-latex) (highlight-code)))

{: blog-links : blog-post : blog-pre}
