(local lmrk (require :lunamark))
(local etlua (require :etlua))
(local {: cat/ : merge-tbls} (require :util))
(local {: load-etlua-templates
        : delete-file!
        : write-file!
        : make-dir!
        : file-exists?
        : read-file} (require :fs))

(local luna-writer (lmrk.writer.html.new {}))

(λ md-compile [md-content ?args]
  "Compiles markdown content string `md-content` to html.
Passes `?args` to luna parser if provided."
  (let [luna-parser (lmrk.reader.markdown.new luna-writer
                                              (or ?args {:link_attributes true}))]
    (luna-parser md-content)))

(λ et-compile [et-ctx templ-name ?params]
  (assert (. et-ctx.templs templ-name)
          (string.format "No template named \"%s\" found" templ-name))
  (let [base-args {:inject_from (λ [templ ?args]
                                  (et-compile et-ctx templ ?args))}
        templ-args (merge-tbls base-args (or ?params {}))
        templ (. et-ctx.templs templ-name)]
    (templ templ-args)))

(λ et-create-ctx [templ-path]
  "Creates an etlua compiler context. Loads and compiles templates from `templ-path`"
  (fn compile-templates [templ-dir]
    (collect [_i {: name : source} (ipairs (load-etlua-templates templ-dir))]
      (do
        (print (string.format "- Compiling template \"%s\"..." name))
        (let [(compiled err) (etlua.compile source)]
          (when (= compiled nil)
            (error err))
          (values name compiled)))))

  (let [ctx {:templs (compile-templates templ-path)}]
    (assert (not= ctx.templs.layout nil) "No layout etlua template defined")
    ctx))

;; TODO: Make an interface to run commands?
(λ tex-compile [cache-path equation inline?]
  "Compile a LaTeX equation that might be inline. Uses `cache-path` as cache directory.
Returns the original `equation` and SVG data of the rendered image.
`{:equation <string> :image <string>}`"
  (local tex-content-templ "
    \\documentclass[border=5pt]{standalone}
    \\usepackage{amsmath}
    \\usepackage{amssymb}
    \\usepackage[T1]{fontenc}
    \\usepackage{xcolor} 
    \\begin{document}
    \\color{white}
    \\begin{equation*}
    \\displaystyle
    %s
    \\end{equation*}
    \\end{document}")
  (local tex-cmd-templ
         "pdflatex -interaction=batchmode -output-directory=\"%s\" \"%s\" >/dev/null 2>&1")
  (local svg-cmd-templ "pdf2svg \"%s\" \"%s\"")
  (let [tex-dir (cat/ cache-path "tex_temp")
        tex-file (cat/ tex-dir "eq.tex")
        tex-pdf (cat/ tex-dir "eq.pdf")
        tex-svg (cat/ tex-dir "eq.svg")
        post-equation (if (not inline?)
                          (.. "\\displaystyle " equation)
                          equation)
        tex-content (string.format tex-content-templ post-equation)
        tex-cmd (string.format tex-cmd-templ tex-dir tex-file)
        svg-cmd (string.format svg-cmd-templ tex-pdf tex-svg)]
    (make-dir! tex-dir)
    (write-file! tex-file tex-content)
    (os.execute tex-cmd)
    (assert (file-exists? tex-pdf) "Failed to compile tex equation")
    (os.execute svg-cmd)
    (assert (file-exists? tex-svg) "Failed to vectorize tex equation")
    (let [image (read-file tex-svg)]
      (delete-file! tex-dir)
      {: equation : image})))

(λ html-highlight-code [script-path cache-path code-lang code-body]
  "Highlight the string of code `code-body` for the langauge `code-lang` using html tags.
Runs a highlighting script from `script-path` and uses `cache-path` as cache folder"
  (let [script (cat/ script-path "highlight.py")
        code-dir (cat/ cache-path "highlight")
        code-input (cat/ code-dir "code.txt")
        code-output (cat/ code-dir "code.html")
        cmd (string.format "python3 \"%s\" %s \"%s\" \"%s\"" script code-lang
                           code-input code-output)]
    (make-dir! code-dir)
    (write-file! code-input code-body)
    (os.execute cmd)
    (assert (file-exists? code-output "Failed to highlight code"))
    (let [result (read-file code-output)]
      (delete-file! code-dir)
      result)))

{: et-create-ctx : et-compile : md-compile : tex-compile : html-highlight-code}
