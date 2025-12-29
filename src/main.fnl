(local inspect (require :inspect))
(local {: write-file : copy-file : filetype : split-dir-file : make-dir}
       (require :fs))

(local {: parse-versions : comp-date : set-comp-date!} (require :meta))
(local {: epoch-to-str-day : truncate-list} (require :util))
(local {: et-load} (require :compiler))
(local {: load-pages} (require :pages))

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

(fn handle-write-content [et page meta]
  (let [versions (icollect [_i detail (ipairs meta.versions)]
                   {:title detail.title
                    :ver detail.ver
                    :date (epoch-to-str-day detail.timestamp)})
        content (et:inject "layout"
                           {:content page.content
                            :comp_date (comp-date)
                            :disable_sidebar page.disable-sidebar
                            :page_name page.name
                            : versions
                            :title page.title})
        (dir _file) (split-dir-file page.dst-path)]
    (make-dir dir)
    (write-file page.dst-path content)))

(fn handle-copy-file [page]
  (copy-file page.src-path page.dst-path))

(fn handle-write-file [page]
  (let [(dir _file) (split-dir-file page.dst-path)]
    (make-dir dir)
    (write-file page.dst-path page.content)))

(fn write-page-files! [et page meta]
  (if (= page.type filetype.page) (handle-write-content et page meta)
      (= page.type filetype.file-write) (handle-write-file page)
      (handle-copy-file page)))

(let [paths (parse-paths)
      {: versions} (parse-versions paths)
      et-ctx (et-load paths)
      pages (load-pages et-ctx paths)]
  (set-comp-date!)
  (each [_i page (ipairs pages)]
    (write-page-files! et-ctx page {:versions (truncate-list versions 5)}))
  (print (string.format "- Page compiled at %s " (comp-date))))
