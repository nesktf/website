(local {: cat/
        : write-file
        : read-file
        : make-dir
        : file-exists?
        : delete-file} (require :fs))

(λ highlight-code-block [paths code-lang code-body]
  (let [script (cat/ paths.script "highlight.py")
        code-dir (cat/ paths.cache "highlight")
        code-input (cat/ code-dir "code.txt")
        code-output (cat/ code-dir "code.html")
        cmd (string.format "python3 \"%s\" %s \"%s\" \"%s\"" script code-lang
                           code-input code-output)]
    (make-dir code-dir)
    (write-file code-input code-body)
    (os.execute cmd)
    (assert (file-exists? code-output "Failed to highlight code"))
    (let [result (read-file code-output)]
      (delete-file code-dir)
      result)))

{: highlight-code-block}
