(local etlua (require :etlua))
(local {: list-dir : split-ext : read-file : cat/ : filetype} (require :fs))
(local {: merge-tbls} (require :util))

(local et-mt {})

(λ et-mt.inject [self templ-name ?params]
  (assert (. self._templs templ-name)
          (string.format "No template named \"%s\" found" templ-name))
  (let [base-args {:inject_from (λ [templ ?args]
                                  (self:inject templ ?args))}
        templ-args (merge-tbls base-args (or ?params {}))
        templ (. self._templs templ-name)]
    (templ templ-args)))

(λ et-mt.page-from-templ [self templ-name layout-params ?page-params]
  (let [content (self:inject templ-name ?page-params)]
    {:type filetype.page
     :title layout-params.title
     :disable-sidebar layout-params.disable-sidebar
     :name layout-params.name
     : content
     :dst-path layout-params.dst-path}))

(λ et-load [paths]
  (let [et (setmetatable {} {:__index et-mt})
        templ-dir paths.templ
        files (list-dir templ-dir)
        templs {}]
    (each [_ filename (ipairs files)]
      (let [(name ext) (split-ext filename)]
        (when (= ext "etlua")
          (print (string.format "- Compiling template \"%s\"..." name))
          (case (etlua.compile (read-file (cat/ templ-dir filename)))
            compiled (set (. templs name) compiled)
            (nil err) (error err)))))
    (assert (. templs "layout") "No layout file in template folder")
    (set et._templs templs)
    et))

{: et-load}
