(local {: blog-page-gen} (require :pages.blog))
(local {: proj-page-gen} (require :pages.projects))
(local {: not-found-page-gen} (require :pages.not-found))
(local {: about-page-gen} (require :pages.about))
(local {: misc-page-gen} (require :pages.misc))
(local {: index-page-gen} (require :pages.index))
(local {: meta-page-gen} (require :pages.meta))
(local {: api-page-gen} (require :pages.api))

(local generators [{:name "index" :make-page index-page-gen}
                   {:name "404" :make-page not-found-page-gen}
                   {:name "about" :make-page about-page-gen}
                   {:name "projects" :make-page proj-page-gen}
                   {:name "blog" :make-page blog-page-gen}
                   {:name "misc" :make-page misc-page-gen}
                   {:name "meta" :make-page meta-page-gen}
                   {:name "api" :make-page api-page-gen}])

(λ load-pages [et paths]
  (local merged-tree [])

  (fn append-page-tree! [make-page]
    (let [page-tree (make-page {: et : paths})]
      (each [_i tree-elem (ipairs page-tree)]
        (table.insert merged-tree tree-elem))))

  (each [_i {: name : make-page} (ipairs generators)]
    (print (string.format "- Compiling page tree for \"%s\"" name))
    (append-page-tree! make-page))
  merged-tree)

{: load-pages}
