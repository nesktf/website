(local lmrk (require :lunamark))
(local toml (require :toml))
(local {: cat/ : list-dir : split-ext : read-file : filetype} (require :fs))
(local {: truncate-list} (require :util))

(local proj-page {:route "projects"})

(λ find-project-paths [project-data-path]
  (fn is-toml-file? [path]
    (let [(_name ext) (split-ext path)]
      (= ext "toml")))

  (fn find-matching-image [filename other-files]
    (. (icollect [_i file (ipairs other-files)]
         (let [(name ext) (split-ext file)]
           (if (and (= name filename) (or (= ext "jpg") (= ext "png")))
               file
               nil))) 1))

  (fn add-data-path [file]
    (if file
        (cat/ project-data-path file)
        nil))

  (let [files (list-dir project-data-path)
        other-files (icollect [_i file (ipairs files)]
                      (if (not (is-toml-file? file))
                          file
                          nil))
        proj-files (icollect [_i file (ipairs files)]
                     (if (is-toml-file? file)
                         (let [(name _ext) (split-ext file)]
                           {:name file
                            :image (add-data-path (find-matching-image name
                                                                       other-files))
                            :path (add-data-path file)})
                         nil))]
    ;; Sort in ascending order
    (table.sort proj-files (fn [proj-a proj-b]
                             (let [num-a (tonumber (proj-a.name:sub 1 2))
                                   num-b (tonumber (proj-b.name:sub 1 2))]
                               (> num-b num-a))))
    proj-files))

(λ parse-project-meta [proj-files]
  (fn parse-proj-toml [toml-content]
    (case (pcall toml.decode toml-content)
      (true toml) toml.PROJECT
      (false err) (error err.reason)))

  (let [out []]
    (each [i proj-file (ipairs proj-files)]
      (let [toml-content (read-file proj-file.path)
            (id _) (split-ext (proj-file.name:sub 4 -1))
            {: name : desc : lang : license : repo : image_desc} (parse-proj-toml toml-content)]
        (assert name (string.format "No name in project \"%s\"" proj-file.name))
        (assert desc (string.format "No desc in project \"%s\"" proj-file.name))
        (set (. out i) {: id
                        : name
                        : desc
                        : lang
                        : license
                        : repo
                        : image_desc
                        :image proj-file.image})))
    out))

(λ proj-top-entries [paths ?limit]
  (let [proj-files (find-project-paths (cat/ paths.data proj-page.route))
        entries (parse-project-meta proj-files)]
    (if (not= ?limit nil)
        (truncate-list entries ?limit)
        entries)))

(λ proj-page-gen [{: et : paths}]
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

{: proj-page-gen : proj-top-entries}
