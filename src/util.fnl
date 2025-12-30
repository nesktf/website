(fn cat/ [...]
  "Concatenate directories. For example, the input `(cat/ \"a\" \"b\")` will return \"a/b\""
  (let [dirs [...]]
    (table.concat dirs "/")))

(λ split-ext [filename]
  "Extract the name and extension for a given filename in the format `<name>.<ext>`"
  (filename:match "^(.+)%.(.+)$"))

(λ path-filename [path-with-file]
  "Extract the filename and directory for a path in the format `<dir>/<filename>`"
  (let [(dir file) (path-with-file:match "^(.+)%/(.+)$")]
    (values file (.. dir "/"))))

(fn truncate-list [list n]
  (let [len (length list)
        out []]
    (if (>= n len)
        list
        (do
          (for [i 1 n]
            (table.insert out (. list i)))
          out))))

(fn merge-tbls [...]
  (let [out {}
        tbls [...]]
    (each [_ tbl (ipairs tbls)]
      (each [k v (pairs tbl)]
        (tset out k v)))
    out))

(λ epoch-to-str [epoch]
  (os.date "%Y/%m/%d %H:%M (GMT-3)" (tonumber epoch)))

(λ epoch-to-str-day [epoch]
  (os.date "%Y/%m/%d" (tonumber epoch)))

{: truncate-list
 : merge-tbls
 : epoch-to-str
 : epoch-to-str-day
 : cat/
 : split-ext
 : path-filename}
