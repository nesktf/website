(local {: truncate-list : cat/ : split-ext} (require :util))

(local {: read-file
        : delete-file!
        : write-file!
        : make-dir!
        : file-exists?
        : file-op} (require :fs))

(local {: tex-compile : md-compile-entry} (require :comp))
(local {: find-md-entries : compile-md-entries} (require :markdown))

(local blog-page {:route "blog"})

(λ tex-md-inject [{: content : files : paths}]
  "Replaces LaTeX equations in the format `$$<eq>$$` or `$<eq>$` inside a markdown page context.
Renders each found equation as an SVG, appends them to the context files and replaces the original
equation text with an <img> tag, wrapped around a <div> if its a block equation (`$$<eq>$$`).
Returns a string with the new markdown content"
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
      (table.insert files {:type file-op.write :content image :dst image-file})
      (set eq-id (+ eq-id 1))
      img-tag))

  ;; Replace equation blocks ($$ $$) and then inline equations ($ $)
  (let [first-replace (content:gsub "%$%$(.-)%$%$" #(replace-eq $1 false))]
    (first-replace:gsub "%$(.-)%$" #(replace-eq $1 true))))

(λ blog-links [entries]
  "Get blog links with format `{:name <string> :url <string> :date <epoch> :tags <string[]>}`"
  ;; From newest to oldest
  (table.sort entries (fn [entry-a entry-b]
                        (let [date-a (tonumber entry-a.date)
                              date-b (tonumber entry-b.date)]
                          (> date-a date-b))))
  (icollect [_i entry (ipairs entries)]
    {:name entry.name
     :url (cat/ "/blog" entry.id)
     :subtitle entry.subtitle
     :date entry.date
     :tags entry.tags}))

(λ blog-entries [paths ?limit]
  "Find the newest blog entries, up to `?limit`.
Returns in a list with in the format `{:name <string> :url <string> :date <epoch>}`"
  (let [data-root (cat/ paths.data blog-page.route)
        entries (blog-links (find-md-entries data-root))]
    (if (not= ?limit nil)
        (truncate-list entries ?limit)
        entries)))

(λ blog-post-process [blog-path {: content : id}]
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

  (let [entry-path (cat/ blog-path id)
        img-dirs (replace-img-dirs content entry-path)
        img-bodies (replace-img-bodies img-dirs)]
    img-bodies))

(λ blog-pre-process [et-ctx]
  (λ highlight-code-blocks [{: paths} html-content]
    (fn parse-code [code-lang code-body]
      (let [script (cat/ paths.script "highlight.py")
            code-dir (cat/ paths.cache "highlight")
            code-input (cat/ code-dir "code.txt")
            code-output (cat/ code-dir "code.html")
            cmd (string.format "python3 \"%s\" %s \"%s\" \"%s\"" script
                               code-lang code-input code-output)]
        (make-dir! code-dir)
        (write-file! code-input code-body)
        (os.execute cmd)
        (assert (file-exists? code-output "Failed to highlight code"))
        (let [result (read-file code-output)]
          (delete-file! code-dir)
          result)))

    (html-content:gsub "```([^%s]*)%s([^%`]*)```" parse-code)))

{: blog-entries : blog-links : blog-post-process : blog-pre-process}
