(local cjson (require :cjson))
(local {: cat/ : filetype} (require :fs))
(local {: proj-top-entries} (require :pages.projects))
(local {: blog-top-entries} (require :pages.blog))

(local api-route "api")

(λ api-page-gen [{: paths}]
  (let [blog-data (icollect [_i entry (ipairs (blog-top-entries paths))]
                    {:name entry.name
                     :subtitle entry.subtitle
                     :tags entry.tags
                     :url entry.url
                     :date (* entry.date 1000)})
        blog-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output api-route "blog.json")
                       :name "api-blog"
                       :content (cjson.encode blog-data)}
        proj-data (icollect [_i entry (ipairs (proj-top-entries paths))]
                    {:name entry.name
                     :lang entry.lang
                     :license entry.license
                     :repo entry.repo
                     :url (string.format "/projects#%s" entry.id)})
        proj-endpoint {:type filetype.file-write
                       :dst-path (cat/ paths.output api-route "projects.json")
                       :name "api-proj"
                       :content (cjson.encode proj-data)}]
    [blog-endpoint proj-endpoint]))

{: api-page-gen}
