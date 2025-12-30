(local lmrk (require :lunamark))
(local etlua (require :etlua))
(local {: cat/ : path-filename : merge-tbls} (require :util))
(local {: write-file!
        : read-file
        : file-exists?
        : delete-file!
        : make-dir!
        : file-op
        : load-etlua-templates} (require :fs))

(local luna-writter (lmrk.writter.html.new {}))

(λ md-compile [md-content ?args]
  "Compiles markdown content string `md-content` to html.
Passes `?args` to luna parser if provided."
  (let [luna-parser (lmrk.reader.markdown.new luna-writter
                                              (or ?args {:link_attributes true}))]
    (luna-parser md-content)))

(λ md-compile-entry [md-entry dest-path ?pre-process]
  "Compiles a markdown entry to html. Modifies paths to use `dest-path` as their root.
Calls `?pre-process` on `md-entry` if provided to preprocess the content string. Returns:
`{:html-content <string> :html-path <path> :files <path[]>}`"
  (fn rebind-paths [html-root]
    (icollect [_i file-path (ipairs md-entry.files)]
      (let [filename (path-filename file-path)]
        (cat/ html-root filename))))

  (let [md-content (if (not= ?pre-process nil)
                       (?pre-process md-entry)
                       md-entry.md-content)
        html-root (cat/ dest-path md-entry.id)
        html-content (md-compile md-content
                                 {:link_attributes true
                                  :smart true
                                  :fenced_code_blocks true})]
    {: html-content
     :html-path (cat/ html-root "index.html")
     :files (rebind-paths html-root)}))

(λ tex-compile [cache-path equation inline?]
  "Compile a LaTeX equation that might be inline. Uses `cache-path` as cache directory.
Returns a table with the tex equation and the source for an svg file with the rendered equation."
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

(λ et-compile [et-ctx templ-name ?params]
  (assert (. et-ctx.templs templ-name)
          (string.format "No template named \"%s\" found" templ-name))
  (let [base-args {:inject_from (λ [templ ?args]
                                  (et-compile et-ctx templ ?args))}
        templ-args (merge-tbls base-args (or ?params {}))
        templ (. et-ctx.templs templ-name)]
    (templ templ-args)))

(λ et-compile-page [et-ctx templ-name layout-params ?page-params]
  (let [content (et-compile et-ctx templ-name ?page-params)]
    {:op file-op.write-tree
     :title layout-params.title
     :disable-sidebar layout-params.disable-sidebar
     :name layout-params.name
     : content
     :dst-path layout-params.dst-path}))

(λ et-create-ctx [templ-path]
  "Creates an etlua compiler context. Loads and compiles templates from `templ-path`"
  (fn compile-templates [templ-dir]
    (collect [_i {: name : source} (ipairs (load-etlua-templates templ-dir))]
      (print (string.format "- Compiling template \"%s\"..." name))
      (case (etlua.compile source)
        compiled (values name compiled)
        (nil err) (error err))))

  (let [ctx {:templs (compile-templates templ-path)}]
    (assert (not= ctx.templs.layout nil) "No layout etlua template defined")
    ctx))

{: et-create-ctx
 : et-compile
 : et-compile-page
 : md-compile-entry
 : md-compile
 : tex-compile}
