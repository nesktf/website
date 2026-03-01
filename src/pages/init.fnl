(local cjson (require :cjson))
(local {: epoch-to-str : path-filename} (require :util))
(local {: file-op : load-md-entries : load-projects} (require :fs))
(local {: blog-post : blog-pre : blog-links} (require :pages.blog))
(local {: md-compile : et-compile} (require :compiler))
(local {: cat/ : flatten-tbl : truncate-list : epoch-to-str-day}
       (require :util))

(local preview-blog-count 5)
(local preview-proj-count 5)

(λ compile-page [et params]
  (let [{: title : name : templ : file : route : args : nosidebar : content} params
        templ-args (if (= args nil) {}
                       (= (type args) "function") (args)
                       args)
        route-file (or file "index.html")
        page-content (or content (et-compile et templ templ-args))]
    (assert (not= title nil) "No page title provided")
    (assert (not= name nil) "No page name/template provided")
    (assert (not= route nil) "No page route provided")
    {:op file-op.write-layout
     :layout {: title :nosidebar (or nosidebar false)}
     : name
     :content page-content
     :route (cat/ route route-file)}))

(λ build-simple [{: et : comp-date : version-data : previews}]
  (fn make-meta-args []
    (let [{: versions : todo} version-data]
      {:epoch_to_str epoch-to-str
       :compilation_date comp-date
       : todo
       : versions}))

  (fn make-index-args []
    (let [{:blog blog_entries :proj projects} previews]
      {: blog_entries : projects :epoch_to_str epoch-to-str}))

  (local pages [;; Index
                {:name "index"
                 :templ "index"
                 :title "Home"
                 :route "/"
                 :args make-index-args}
                ;; Not found
                {:name "404"
                 :templ "404"
                 :title "Page not found :("
                 :route "/"
                 :file "not_found.html"
                 :nosidebar true}
                ;; Meta
                {:name "meta"
                 :templ "meta"
                 :title "Meta"
                 :route "/meta"
                 :args make-meta-args}
                ;; About
                {:name "about"
                 :templ "about"
                 :title "About me"
                 :route "/about"}
                ;; Other pages
                {:name "pages"
                 :templ "pages"
                 :title "Other pages"
                 :route "/pages"}])
  (icollect [_i page (ipairs pages)]
    (do
      (print (string.format "- Building page \"%s\"" page.name))
      (compile-page et page))))

(λ build-api [{: blog-entries : proj-entries}]
  (fn endpoint [route name make-data]
    (print (string.format "- Building endpoint \"%s\"" name))
    {:op file-op.write
     :route (cat/ "/api" route)
     : name
     :content (cjson.encode (make-data))})

  (fn collect-blog []
    (icollect [_i entry (ipairs blog-entries)]
      {:name entry.name
       :subtitle entry.subtitle
       :tags entry.tags
       :url (string.format "/blog/%s" entry.id)
       ;; JS uses milliseconds
       :date (* entry.date 1000)}))

  (fn collect-proj []
    (icollect [_i entry (ipairs proj-entries)]
      {:name entry.name
       :lang entry.lang
       :license entry.license
       :repo entry.repo
       :url (string.format "/projects#%s" entry.id)}))

  [(endpoint "blog.json" "api-blog" collect-blog)
   (endpoint "projects.json" "api-proj" collect-proj)])

(λ build-blog [{: et : paths : blog-entries}]
  (fn compile-entry [entry]
    (md-compile (blog-pre entry.content entry.files paths)
                {:link_attributes true :smart true :fenced_code_blocks true}))

  (fn compile-blog-entry [entry]
    (print (string.format "- Building blog entry \"%s\"" entry.id))
    (let [md_content (compile-entry entry blog-pre)
          pub_date (epoch-to-str entry.date)
          mod_date (epoch-to-str entry.date-modified)
          tag-string (accumulate [str "" i tag (ipairs entry.tags)]
                       (if (= i (length entry.tags))
                           (.. str tag)
                           (.. str tag ", ")))]
      (-> (et-compile et "blog-entry"
                      {: md_content
                       : pub_date
                       : mod_date
                       :tag_string tag-string
                       :entry_title entry.name
                       :entry_subtitle entry.subtitle})
          (blog-post entry.id))))

  (fn reroute-files [entry-files entry-route entries]
    (if (= (length entry-files) 0)
        entries
        (icollect [_i file (ipairs entry-files) &into entries]
          (if (= file.op file-op.write)
              {:op file-op.write
               :content file.content
               :name file.name
               :route (cat/ entry-route file.name)}
              {:op file-op.copy
               :path file.path
               :name file.name
               :route (cat/ entry-route file.name)}))))

  (fn collect-entries [blog-tree]
    (icollect [_i entry (ipairs blog-entries) &into blog-tree]
      (let [entry-route (cat/ "/blog" entry.id)]
        (->> [(compile-page et
                            {:title entry.name
                             :op file-op.write
                             :name (string.format "blog-entry-%s" entry.id)
                             :templ "blog-entry"
                             :content (compile-blog-entry entry)
                             :route entry-route})]
             (reroute-files entry.files entry-route)))))

  (->> [(compile-page et
                      {:title "Blog entries"
                       :route "/blog"
                       :templ "blog"
                       :name "blog"
                       :args {:epoch_to_str epoch-to-str
                              :blog_links (blog-links blog-entries)}})]
       (collect-entries)
       (flatten-tbl)))

(λ build-projects [{: et : proj-entries}]
  (print "- Building projects page")

  (fn image-path [name]
    (if name
        (let [(image-file _image-dir) (path-filename name)]
          (string.format "projects/%s" image-file))
        nil))

  (fn generate-tree [projects]
    (let [root [(compile-page et
                              {:title "My projects"
                               :route "/projects"
                               :name "projects"
                               :templ "projects"
                               :args {: projects}})]]
      (icollect [_ proj (ipairs projects) &into root]
        (if proj.image-src
            {:path proj.image-src
             :op file-op.copy
             :route proj.image
             :name proj.name}
            nil))))

  (->> (icollect [_ proj (ipairs proj-entries)]
         {:id proj.id
          :lang proj.lan
          :license proj.license
          :name proj.name
          :repo proj.repo
          :image (image-path proj.image)
          :image-src proj.image
          :image_desc proj.image_desc
          ;; Add new line to make sure we insert a <p> tag
          :desc (md-compile (.. proj.desc "\n"))})
       (generate-tree)))

(λ load-pages [{: et : paths : comp-date : version-data}]
  "Load page data"
  (fn make-build-ctx [blog-entries proj-entries]
    {: et
     : paths
     : comp-date
     : blog-entries
     : proj-entries
     :previews {:blog (truncate-list blog-entries preview-blog-count)
                :proj (truncate-list proj-entries preview-proj-count)}
     : version-data})

  (fn collect-builders [builders build-ctx]
    (icollect [_i builder (ipairs builders)]
      (builder build-ctx)))

  (let [blog-entries (load-md-entries (cat/ paths.data "blog"))
        proj-entries (load-projects (cat/ paths.data "projects"))]
    (->> (make-build-ctx blog-entries proj-entries)
         (collect-builders [build-blog build-projects build-api build-simple])
         (flatten-tbl))))

(λ fill-page-layout [{: et : version-data : comp-date : paths}
                     {: name : layout : content : route}]
  "Insert HTML layout inside pages. Basically converts `file-op.write-layout` to `file-op.write`"
  (fn add-layout [versions]
    (et-compile et "layout" {: content
                             :comp_date comp-date
                             :disable_sidebar layout.nosidebar
                             :page_name name
                             : versions
                             :title layout.title}))

  {: name
   :op file-op.write
   :route (cat/ paths.output route)
   :content (-> (icollect [_i detail (ipairs version-data.versions)]
                  {:title detail.title
                   :ver detail.ver
                   :date (epoch-to-str-day detail.timestamp)})
                (add-layout))})

{: load-pages : fill-page-layout}
