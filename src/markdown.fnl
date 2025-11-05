(local lmrk (require :lunamark))
(local toml (require :toml))
(local {: read-file
        : list-dir
        : split-ext
        : is-dir?
        : cat/
        : filetype
        : last-modification} (require :fs))

(λ find-md-entries [root-path]
  (fn parse-md-header [md-file-path]
    (let [content (read-file md-file-path)
          toml-header (assert (content:match "^%+%+%+(.-)%+%+%+")
                              (.. "No header in " md-file-path))
          header (. (toml.decode toml-header) :BLOG_ENTRY)]
      {:name header.title
       :subtitle header.subtitle
       :date header.timestamp
       :id header.slug
       :tags header.tags}))

  (fn is-md-file? [path]
    (let [(_name ext) (split-ext path)]
      (= ext "md")))

  (fn filter-md [dir-list]
    (icollect [_i {: dir-name : dir-path} (ipairs dir-list)]
      (let [files (list-dir dir-path)
            md-file (. (icollect [_j file (ipairs files)]
                         (if (is-md-file? file)
                             {:src (cat/ dir-path file)
                              :dst (cat/ dir-name file)}
                             nil)) 1)
            cpy-files (icollect [_j file (ipairs files)]
                        (if (not (is-md-file? file))
                            {:type filetype.file
                             :src (cat/ dir-path file)
                             :dst file}
                            nil))
            date-modified (last-modification md-file.src)
            {: name : id : tags : date : subtitle} (parse-md-header md-file.src)]
        {: md-file
         : cpy-files
         : name
         : id
         : tags
         : date
         : date-modified
         : subtitle})))

  (filter-md (icollect [_i dir-name (ipairs (list-dir root-path))]
               (if (is-dir? (cat/ root-path dir-name))
                   {: dir-name :dir-path (cat/ root-path dir-name)}
                   nil))))

(λ compile-md-entries [paths md-entries ?pre-process!]
  (icollect [_i {: id
                 : name
                 : date
                 : date-modified
                 : subtitle
                 : tags
                 : md-file
                 : cpy-files} (ipairs md-entries)]
    (let [luna-writer (lmrk.writer.html.new {})
          luna-parser (lmrk.reader.markdown.new luna-writer
                                                {:link_attributes true
                                                 :smart true
                                                 :fenced_code_blocks true})
          file-content (: (read-file md-file.src) :gsub "^%+%+%+(.-)%+%+%+" "")
          md-content (if ?pre-process!
                         (?pre-process! {: id
                                         : date
                                         : name
                                         :content file-content
                                         :files cpy-files
                                         : paths})
                         file-content)]
      {: name
       : id
       : subtitle
       : date
       : tags
       : date-modified
       :files cpy-files
       :content (luna-parser md-content)})))

(λ compile-md-content [content]
  (let [luna-writer (lmrk.writer.html.new {})
        luna-parser (lmrk.reader.markdown.new luna-writer
                                              {:link_attributes true})]
    (luna-parser content)))

{: find-md-entries : compile-md-entries : compile-md-content}
