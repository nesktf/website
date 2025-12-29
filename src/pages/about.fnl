(local {: cat/} (require :fs))

(local about-page {:route "about"})

(λ about-page-gen [{: et : paths}]
  [(et:page-from-templ "about"
                       {:title "About Me"
                        :name "about"
                        :dst-path (cat/ paths.output about-page.route
                                        "index.html")} {})])

{: about-page-gen}
