(local cjson (require :cjson))
(local {: cat/ : filetype} (require :fs))
(local {: proj-top-entries} (require :pages.projects))
(local {: blog-top-entries} (require :pages.blog))

(local api-route "api")

(λ api-page-gen [{: paths}]
  (let [blog-data (blog-top-entries paths)
        blog-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output api-route "blog.json")
                       :content (cjson.encode blog-data)}
        proj-data (icollect [_i entry (ipairs (proj-top-entries paths))]
                    {:name entry.name
                     :lang entry.lang
                     :license entry.license
                     :repo entry.repo
                     :url (string.format "/projects#%s" entry.id)})
        proj-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output api-route "projects.json")
                       :content (cjson.encode proj-data)}]
    [blog-endpoint proj-endpoint]))

{: api-page-gen}
