(local {: cat/} (require :fs))
(local {: epoch-to-str} (require :util))

(local {: parse-versions : comp-date} (require :meta))

(local meta-page {:route "meta"})

(λ meta-page-gen [{: et : paths}]
  (let [{: versions : todo} (parse-versions paths)]
    [(et:page-from-templ "meta"
                         {:title "Changelog"
                          :dst-path (cat/ paths.output meta-page.route
                                          "index.html")}
                         {:epoch_to_str epoch-to-str
                          :compilation_date (comp-date)
                          : todo
                          : versions})]))

{: meta-page-gen}
