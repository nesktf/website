(local {: truncate-list : epoch-to-str} (require :util))
(local {: cat/ : filetype} (require :fs))
(local {: find-md-entries : compile-md-entries} (require :markdown))
(local {: tex-md-inject} (require :latex))
(local {: replace-img-dirs : replace-img-bodies : sanitize-code-blocks}
       (require :postprocess))

(local blog-page {:route "blog"})

(λ ext-blog-links [entries]
  "Get blog links with format `{:name <string> :url <string> :date <epoch> :tags <string[]>}`"
  ;; From newest to oldest
  (table.sort entries (fn [entry-a entry-b]
                        (let [date-a (tonumber entry-a.date)
                              date-b (tonumber entry-b.date)]
                          (> date-a date-b))))
  (icollect [_i entry (ipairs entries)]
    {:name entry.name
     :url (cat/ "/blog" entry.id)
     :date entry.date
     :tags entry.tags}))

(λ blog-page-gen [{: et : paths}]
  "Generate the blog page tree.
Given a compilation context, checks at `${paths.data}/blog` for markdown entries and builds an
entire page tree with root at `${paths.output}/blog`.
"
  (fn content-post-process [blog-path {: content : id}]
    (let [entry-path (cat/ blog-path id)
          img-dirs (replace-img-dirs content entry-path)
          img-bodies (replace-img-bodies img-dirs)]
      (sanitize-code-blocks img-bodies)))

  (fn inject-blog-entry [et blog-path entry]
    (let [md_content (content-post-process blog-path entry)
          pub_date (epoch-to-str entry.date)
          mod_date (epoch-to-str entry.date-modified)
          tag-string (accumulate [str "" i tag (ipairs entry.tags)]
                       (if (= i (length entry.tags))
                           (.. str tag)
                           (.. str tag ", ")))]
      (et:inject "blog-entry"
                 {: md_content
                  : pub_date
                  : mod_date
                  :tag_string tag-string
                  :entry_title entry.name
                  :entry_subtitle entry.subtitle})))

  (let [output-dir (cat/ paths.output blog-page.route)
        data-root (cat/ paths.data blog-page.route)
        entries (find-md-entries data-root)
        parsed-entries (compile-md-entries paths entries tex-md-inject)
        tree [(et:page-from-templ "blog"
                                  {:title "Blog Entries"
                                   :dst-path (cat/ paths.output blog-page.route
                                                   "index.html")}
                                  {:epoch_to_str epoch-to-str
                                   :blog_links (ext-blog-links entries)})]]
    (each [_i entry (ipairs parsed-entries)]
      (table.insert tree
                    {:title entry.name
                     :type filetype.page
                     :content (inject-blog-entry et blog-page.route entry)
                     :dst-path (cat/ output-dir entry.id "index.html")})
      (each [_j file (ipairs entry.files)]
        (table.insert tree
                      {:type file.type
                       :content file.content
                       :src-path file.src
                       :dst-path (cat/ output-dir entry.id file.dst)})))
    tree))

(λ blog-top-entries [paths ?limit]
  "Find the newest blog entries, up to `?limit`.
Returns in a list with in the format `{:name <string> :url <string> :date <epoch>}`"
  (let [data-root (cat/ paths.data blog-page.route)
        entries (ext-blog-links (find-md-entries data-root))]
    (if (not= ?limit nil)
        (truncate-list entries ?limit)
        entries)))

{: blog-page-gen : blog-top-entries}
