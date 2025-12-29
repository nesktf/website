(local {: cat/} (require :fs))

(local misc-page {:route "pages"})

(λ misc-page-gen [{: et : paths}]
  [(et:page-from-templ "pages"
                       {:title "Other pages"
                        :name "pages"
                        :dst-path (cat/ paths.output misc-page.route
                                        "index.html")} {})])

{: misc-page-gen}
