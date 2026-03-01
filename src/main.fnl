(local {: load-versions} (require :fs))
(local {: epoch-to-str : cat/} (require :util))
(local {: et-create-ctx} (require :compiler))
(local {: load-pages : fill-page-layout} (require :pages))
(local {: file-op : write-page-tree!} (require :fs))

(fn on-die [msg]
  (print (string.format "ERROR: %s" msg))
  (os.exit 1))

(fn parse-paths []
  (let [paths {:templ (. arg 1)
               :src (. arg 2)
               :output (. arg 3)
               :data (. arg 4)
               :cache (. arg 5)
               :script (. arg 6)}]
    (each [name path (pairs paths)]
      (when (not path)
        (on-die (string.format "Path '%s' missing" name)))
      (print (string.format "- Using path '%s' for %s directory" path name)))
    paths))

(fn fill-layouts [page-ctx pages]
  (local paths page-ctx.paths)

  (λ relocate-write-route [{: op : content : name : route}]
    {: op : content : name :route (cat/ paths.output route)})

  (λ relocate-copy-route [{: op : path : route}]
    {: op : path :route (cat/ paths.output route)})

  (icollect [_ page (ipairs pages)]
    (if (= page.op file-op.write-layout) (fill-page-layout page-ctx page)
        (= page.op file-op.write) (relocate-write-route page)
        (relocate-copy-route page))))

(let [comp-date (-> (os.time)
                    (epoch-to-str))
      paths (parse-paths)
      version-data (load-versions (cat/ paths.data "version.toml"))
      et (et-create-ctx paths.templ)
      page-ctx {: et : paths : comp-date : version-data}]
  (->> (load-pages page-ctx)
       (fill-layouts page-ctx)
       (write-page-tree!)))

(print "- Done!!!")
