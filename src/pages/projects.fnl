(local toml (require :toml))
(local {: split-ext : read-file} (require :fs))
(local {: truncate-list} (require :util))
(local {: find-project-paths} (require :fs))

(λ project-entries [project-root ?limit]
  (fn parse-entries []
    (icollect [_i proj-file (ipairs (find-project-paths project-root))]
      (parse-project proj-file)))

  (if (not= ?limit nil)
      (truncate-list (parse-entries) ?limit)
      (parse-entries)))

{: project-entries : parse-project}
