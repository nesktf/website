(local cjson (require :cjson))
(local {: epoch-to-str} (require :util))
(local {: parse-versions : comp-date} (require :meta))
(local {: cat/ : filetype} (require :fs))

(local preview-blog-count 5)
(local preview-proj-count 5)

(λ build-api [paths blog-entries proj-entries]
  (fn collect-blog []
    (icollect [_i entry (ipairs blog-entries)]
      {:name entry.name
       :subtitle entry.subtitle
       :tags entry.tags
       :url entry.url
       :date (* entry.date 1000)}))

  (fn collect-proj []
    (icollect [_i entry (ipairs proj-entries)]
      {:name entry.name
       :lang entry.lang
       :license entry.license
       :repo entry.repo
       :url (string.format "/projects#%s" entry.id)}))

  (let [blog-data (collect-blog)
        blog-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output "api/blog.json")
                       :name "api-blog"
                       :content (cjson.encode blog-data)}
        proj-data (collect-proj)
        proj-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output "api/projects.json")
                       :name "api-proj"
                       :content (cjson.encode proj-data)}]
    [blog-endpoint proj-endpoint]))

(λ build-simple [{: paths}]
  (fn make-meta-args []
    (let [{: versions : todo} (parse-versions paths)]
      {:epoch_to_str epoch-to-str
       :compilation_date (comp-date)
       : todo
       : versions}))

  (local pages
         [;; Index
          {:name "index" :title "Home" :route "index.html"}
          ;; Not found
          {:name "not-found"
           :title "Page not found :("
           :route "not_found.html"
           :nosidebar true}
          ;; Meta
          {:name "meta"
           :title "Meta"
           :route "meta/index.html"
           :args make-meta-args}
          ;; About
          {:name "about" :title "About me" :route "about/index.html"}
          ;; Other pages
          {:name "pages" :title "Other pages" :route "pages/index.html"}]))

(λ build-blog [{: et : paths}]
  (fn content-pre-process [et-ctx]
    (let [md-content (tex-md-inject et-ctx)]
      (sanitize-code-blocks et-ctx md-content)))

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
        parsed-entries (compile-md-entries paths entries content-pre-process)
        tree [(et:page-from-templ "blog"
                                  {:title "Blog Entries"
                                   :dst-path (cat/ paths.output blog-page.route
                                                   "index.html")
                                   :name "blog"}
                                  {:epoch_to_str epoch-to-str
                                   :blog_links (ext-blog-links entries)})]]
    (each [_i entry (ipairs parsed-entries)]
      (table.insert tree
                    {:title entry.name
                     :type filetype.page
                     :name "blog-entry"
                     :content (inject-blog-entry et blog-page.route entry)
                     :dst-path (cat/ output-dir entry.id "index.html")})
      (each [_j file (ipairs entry.files)]
        (table.insert tree
                      {:type file.type
                       :content file.content
                       :src-path file.src
                       :dst-path (cat/ output-dir entry.id file.dst)})))
    tree))

(λ build-projects [et paths projects]
  (let [proj-files (find-project-paths (cat/ paths.data proj-page.route))
        proj-meta (parse-project-meta proj-files)
        luna-writer (lmrk.writer.html.new {})
        luna-parser (lmrk.reader.markdown.new luna-writer
                                              {:link_attributes true})
        tree []]
    (each [_i proj (ipairs proj-meta)]
      (when proj.image
        (let [(_name ext) (split-ext proj.image)
              new-path (cat/ paths.output proj-page.route (.. proj.id "." ext))]
          (table.insert tree {:type filetype.file
                              :src-path proj.image
                              :dst-path new-path})
          (set proj.image (new-path:gsub paths.output ""))))
      (set proj.desc (luna-parser proj.desc)))
    (table.insert tree
                  (et:page-from-templ "projects"
                                      {:title "My Projects"
                                       :dst-path (cat/ paths.output
                                                       "projects/index.html")
                                       :name "projects"}
                                      {:projects proj-meta}))
    tree))

(λ load-pages [et paths]
  (let [page-tree []
        blog-entries (load-md-entries (cat/ paths.data "blog"))
        preview-blog (truncate-list blog-entries preview-blog-count)
        project-entries (load-projects (cat/ paths.data "projects"))
        preview-proj (truncate-list project-entries preview-proj-count)]
    page-tree)

  (fn append-page-tree! [make-page]
    (let [page-tree (make-page {: et : paths})]
      (each [_i tree-elem (ipairs page-tree)]
        (table.insert merged-tree tree-elem))))

  (each [_i {: name : make-page} (ipairs generators)]
    (print (string.format "- Compiling page tree for \"%s\"" name))
    (append-page-tree! make-page))
  merged-tree)

{: load-pages}
