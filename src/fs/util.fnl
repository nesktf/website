(local lfs (require :lfs))
(local {: path-filename} (require :util))

(λ read-file [path]
  "Read a file at `path` as text and return it's contents"
  (case (io.open path "r")
    file (let [content (file:read "*all")]
           (file:close)
           content)
    (nil err) (values nil err)))

(λ write-file! [path content]
  "Write a file at `path` as text with the given content string"
  (case (io.open path "w")
    file (do
           (file:write content)
           (file:close))
    (nil err) (values nil err)))

(λ list-dir [dir-path]
  "Lists all files at `dir-path`. Not recursive."
  (let [files []]
    (each [file (lfs.dir dir-path)]
      (when (and (not= file ".") (not= file ".."))
        (table.insert files file)))
    files))

(λ file-exists? [path]
  "Checks if a file exists at `path`"
  (case (io.open path "r")
    file (do
           (file:close)
           true)
    (nil _err) false))

(λ make-dir! [path]
  "Creates a directory at `path`"
  ;; Dirty hack
  (os.execute (string.format "mkdir -p \"%s\"" path))
  path)

(λ copy-file! [from to]
  "Copy a file from `from` to `to`"
  ;; Dirty hack again
  (let [(_name dir) (path-filename to)]
    (make-dir! dir)
    (os.execute (string.format "cp \"%s\" \"%s\"" from to))))

(λ delete-file! [path]
  "Delete a file at `path`. If it's a directory, its recursively deleted."
  ;; I love dirty hacks
  (os.execute (string.format "rm -rf \"%s\"" path)))

(λ is-dir? [path]
  "Check if a directory exists at `path`"
  (let [attr (lfs.attributes path)]
    (= attr.mode "directory")))

(λ last-modification [path]
  "Get the last modification date for a file at `path`"
  (. (lfs.attributes path) :modification))

{: read-file
 : write-file!
 : list-dir
 : file-exists?
 : copy-file!
 : make-dir!
 : delete-file!
 : last-modification
 : is-dir?}
