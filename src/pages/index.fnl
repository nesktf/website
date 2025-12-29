(local {: cat/} (require :fs))
(local {: epoch-to-str} (require :util))
(local {: blog-top-entries} (require :pages.blog))
(local {: proj-top-entries} (require :pages.projects))

(λ index-page-gen [{: et : paths}]
  [(et:page-from-templ "index"
                       {:title "Home"
                        :name "index"
                        :dst-path (cat/ paths.output "index.html")}
                       {:epoch_to_str epoch-to-str
                        :projects (proj-top-entries paths 5)
                        :blog_entries (blog-top-entries paths 5)})])

{: index-page-gen}
