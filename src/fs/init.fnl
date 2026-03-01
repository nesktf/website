(local {: cat/ : split-ext : path-filename} (require :util))
(local {: read-file
        : write-file!
        : file-exists?
        : list-dir
        : make-dir!
        : copy-file!
        : delete-file!
        : is-dir?
        : last-modification} (require :fs.util))

(local file-op {:write 1 :copy 2 :write-layout 3})

(local toml (require :toml))

(λ load-md-entries [root-path]
  "Load and parse markdown entries located at `root-path` with format:
`{:content <string> :files [{:path <path> :name <string>}]
  :name <string> :id <string> :subtitle <string>
  :tags <string[]> :date <epoch> :date-modified <epoch>}`"
  (assert (is-dir? root-path)
          (string.format "Directory %s not found" root-path))

  (fn parse-md-file [md-file-path]
    (let [content (read-file md-file-path)
          header-pat "^%+%+%+(.-)%+%+%+\n"
          toml-header (assert (content:match header-pat)
                              (string.format "No header defined in %s"
                                             md-file-path))
          decoded (toml.decode toml-header)
          header (assert decoded.BLOG_ENTRY
                         (string.format "No header defined in %s" md-file-path))]
      {:content (content:gsub header-pat "")
       :name (assert header.title
                     (string.format "No name defined in %s" md-file-path))
       :subtitle (or header.subtitle "")
       :date (assert header.timestamp
                     (string.format "No timestamp defined in %s" md-file-path))
       :id (assert header.slug
                   (string.format "No slug defined in %s" md-file-path))
       :tags (or header.tags [])}))

  (fn md-file? [path]
    (let [(_name ext) (split-ext path)]
      (= ext "md")))

  (fn find-entry-files [entry-path]
    (let [files (list-dir entry-path)
          md-path (. (icollect [_j file (ipairs files)]
                       (if (md-file? file)
                           (cat/ entry-path file)
                           nil)) 1)
          other-files (icollect [_j file (ipairs files)]
                        (if (not (md-file? file))
                            {:path (cat/ entry-path file) :name file}
                            nil))]
      {: md-path : other-files}))

  (fn find-md-dirs []
    (icollect [_i entry-name (ipairs (list-dir root-path))]
      (if (is-dir? (cat/ root-path entry-name))
          (cat/ root-path entry-name)
          nil)))

  (let [entries []]
    (icollect [_i entry-path (ipairs (find-md-dirs)) &into entries]
      (let [{: md-path : other-files} (find-entry-files entry-path)
            date-modified (last-modification md-path)
            {: content : name : id : tags : date : subtitle} (parse-md-file md-path)]
        {: content
         :files other-files
         : name
         : id
         : tags
         : date
         : date-modified
         : subtitle}))
    (table.sort entries #(> $1.date $2.date))
    entries))

(λ load-etlua-templates [root-path]
  "Load etlua template files located at `root-path` with format:
`{:name <string> :source <string>}`"
  (assert (is-dir? root-path)
          (string.format "Directory %s not found" root-path))
  (let [files (list-dir root-path)]
    (icollect [_i filename (ipairs files)]
      (let [(name ext) (split-ext filename)]
        (if (= ext "html")
            {: name :source (read-file (cat/ root-path filename))}
            nil)))))

(λ load-projects [root-path]
  "Load and parse project files located at `root-path` with format:
`{:id <string> :name <string> :desc <string>
 :lang <string> :license <string> :repo <url>
 :image_desc <string> :image <path>}`"
  (assert (is-dir? root-path)
          (string.format "Directory %s not found" root-path))

  (fn toml-file? [path]
    (let [(_name ext) (split-ext path)]
      (= ext "toml")))

  (fn find-matching-image [filename other-files]
    (. (icollect [_i file (ipairs other-files)]
         (let [(name ext) (split-ext file)]
           (if (and (= name filename) (or (= ext "jpg") (= ext "png") (= ext "gif")))
               file
               nil))) 1))

  (fn find-files []
    (let [files (list-dir root-path)
          other-files (icollect [_i file (ipairs files)]
                        (if (not (toml-file? file))
                            file
                            nil))]
      (icollect [_i file (ipairs files)]
        (if (toml-file? file)
            (let [(name _ext) (split-ext file)
                  image (find-matching-image name other-files)]
              {:name file
               :path (cat/ root-path file)
               :image (if (not= image nil)
                          (cat/ root-path image)
                          nil)})
            nil))))

  (λ parse-project [proj-file]
    (fn parse-proj-toml [toml-content]
      (case (pcall toml.decode toml-content)
        (true toml) toml.PROJECT
        (false err) (error err.reason)))

    (let [toml-content (read-file proj-file.path)
          (id _) (split-ext (proj-file.name:sub 4 -1))
          {: name : desc : lang : license : repo : image_desc} (parse-proj-toml toml-content)]
      (assert name (string.format "No name in project \"%s\"" proj-file.name))
      (assert desc (string.format "No desc in project \"%s\"" proj-file.name))
      {: id
       : name
       : desc
       : lang
       : license
       : repo
       : image_desc
       :image proj-file.image}))

  (let [proj-files (find-files)]
    ;; Sort in ascending order
    (table.sort proj-files (fn [proj-a proj-b]
                             (let [num-a (tonumber (proj-a.name:sub 1 2))
                                   num-b (tonumber (proj-b.name:sub 1 2))]
                               (> num-b num-a))))
    (icollect [_i proj-file (ipairs proj-files)]
      (parse-project proj-file))))

(λ load-versions [file-path]
  "Load and parse versions from version file located at `file-path` with format:
`{:versions [{:ver <string> :title <string> :changes <string[]> :timestamp <epoch>}]
 :todo <string[]>}`"
  (fn collect-versions [toml]
    (icollect [ver detail (pairs toml)]
      (if (not= ver "TODO")
          {: ver
           :timestamp (assert detail.timestamp
                              (string.format "No timestamp in version %s" ver))
           :title (assert detail.title
                          (string.format "No title in version %s" ver))
           :changes (assert detail.changes
                            (string.format "No changes in version %s" ver))}
          nil)))

  (let [content (assert (read-file file-path)
                        (string.format "Version file %s not found" file-path))
        toml-content (toml.decode content)
        todo (or (?. toml-content :TODO :todo) [])
        versions (collect-versions toml-content)]
    (table.sort versions #(> $1.timestamp $2.timestamp))
    {: versions : todo}))

(λ write-page-tree! [pages]
  "Write a page tree. Each entry needs to have an `op` field for the type of operation:
- `write`: `{:content <string> :name <string> :path <path>}`
- `copy`: `{:src <path> :path <path>}`"

  (λ do-copy-page! [{: route : path}]
    (print (string.format "- Copying file \"%s\" to \"%s\"" path route))
    (copy-file! path route))

  (λ do-write-page! [{: name : route : content}]
    (print (string.format "- Writting file \"%s\" to \"%s\"" name route))
    (write-file! route content))

  (each [_ page (ipairs pages)]
    (let [(_file dir) (path-filename page.route)]
      (make-dir! dir)
      (match page.op
        file-op.copy (do-copy-page! page)
        file-op.write (do-write-page! page)))))

{: read-file
 : write-file!
 : file-exists?
 : list-dir
 : make-dir!
 : copy-file!
 : delete-file!
 : is-dir?
 : load-etlua-templates
 : load-md-entries
 : load-projects
 : load-versions
 : write-page-tree!
 : file-op}
