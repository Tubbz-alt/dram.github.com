(defglobal ?*page-directory* = "_sources/pages/")
(defglobal ?*post-directory* = "_sources/posts/")
(defglobal ?*output-directory* = "./")

;;;
;;; BEGIN OF HELPER FUNCTION DEFINIATIONS
;;;

(deffunction tcl ($?words)
  (bind ?word-objs (tcl-new-obj))
  (tcl-incr-ref-count ?word-objs)
  (foreach ?word ?words
    (tcl-list-obj-append-element ?word-objs
                                 (tcl-new-string-obj ?word -1)))
  (bind ?code
    (tcl-eval-objv (tcl-list-obj-get-elements ?word-objs) /))
  (tcl-decr-ref-count ?word-objs)
  (if (eq ?code /ok/)
   then (tcl-get-obj-result)
   else (bind ?returns (tcl-get-return-options ?code))
        (tcl-incr-ref-count ?returns)
        (tcl-write-obj (tcl-get-std-channel /stderr/) ?returns)
        (tcl-decr-ref-count ?returns)
        FALSE))

(deffunction tcl/b ($?words)
  (if (bind ?result (tcl (expand$ ?words)))
   then (tcl-incr-ref-count ?result)
        (bind ?b (tcl-get-boolean-from-obj ?result))
        (tcl-decr-ref-count ?result)
        ?b
   else FALSE))

(deffunction tcl/l ($?words)
  (if (bind ?result (tcl (expand$ ?words)))
   then (tcl-incr-ref-count ?result)
        (bind ?l (tcl-get-long-from-obj ?result))
        (tcl-decr-ref-count ?result)
        ?l
   else FALSE))

(deffunction tcl/m ($?words)
  (if (bind ?result (tcl (expand$ ?words)))
   then (tcl-incr-ref-count ?result)
        (bind ?m (tcl-split-list (tcl-get-string ?result)))
        (tcl-decr-ref-count ?result)
        ?m
   else FALSE))

(deffunction tcl/s ($?words)
  (if (bind ?result (tcl (expand$ ?words)))
   then (tcl-incr-ref-count ?result)
        (bind ?s (tcl-get-string ?result))
        (tcl-decr-ref-count ?result)
        ?s
   else FALSE))

(deffunction run-process ($?command)
  (tcl-close (tcl-open-command-channel ?command /)))

(deffunction with-process (?command ?function-call ?flags)
  (bind ?channel (tcl-open-command-channel ?command ?flags))
  (if (eq ?channel nil)
   then (bind ?returns (tcl-get-return-options /error/))
        (tcl-incr-ref-count ?returns)
        (tcl-write-obj (tcl-get-std-channel /stderr/) ?returns)
        (tcl-decr-ref-count ?returns)
        FALSE
   else (bind ?result (funcall (nth$ 1 ?function-call)
                               ?channel
                               (expand$ (rest$ ?function-call))))
        (tcl-close ?channel)
        ?result))

(deffunction read-line (?channel)
  (bind ?obj (tcl-new-obj))
  (tcl-incr-ref-count ?obj)
  (bind ?result
    (if (= -1 (tcl-gets-obj ?channel ?obj))
     then FALSE
     else (tcl-get-string ?obj)))
  (tcl-decr-ref-count ?obj)
  ?result)

(deffunction read-lines (?channel)
  (bind ?lines (create$))
  (while (bind ?line (read-line ?channel))
    (bind ?lines ?lines ?line))
  ?lines)

(deffunction format-out (?channel ?format $?arguments)
  (tcl-write-chars ?channel (format nil ?format (expand$ ?arguments)) -1))

(deffunction format-string (?format $?arguments)
  (format nil ?format (expand$ ?arguments)))

;;; END OF HELPER FUNCTIONS

;;;
;;; BEGIN OF DATA TEMPLATE DEFINIATIONS
;;;

(deftemplate post
  (slot title (type STRING))
  (slot source (type STRING))
  (slot uri (type STRING))
  (slot creation-date (type STRING)))

;;; END OF DATA TEMPLATES

;;;
;;; BEGIN OF RULE DEFINIATIONS
;;;

(defrule find-post-sources
 =>
  (foreach ?file (tcl/m "glob" "-path" ?*post-directory* "*.sam")
    (bind ?date (sub-string (+ (str-length ?*post-directory*) 1)
                            (+ (str-length ?*post-directory*) 10)
                            ?file))

    (bind ?title
      (progn
        (open ?file file "r")
        (bind ?line (readline file))
        (close file)
        (sub-string (+ (str-length "article: ") 1) (str-length ?line) ?line)))

    (assert (post (title ?title)
                  (source ?file)
                  (uri (str-cat "/blog/"
                                (tcl/s "string" "map" "- /" ?date)
                                "/"
                                (sub-string (+ (str-length ?*post-directory*)
                                               12)
                                            (- (str-length ?file) 4)
                                            ?file)
                                ".html"))
                  (creation-date ?date)))))

(defrule generate-post-html
  (post (source ?source) (uri ?uri) (creation-date ?date))
 =>
  (bind ?target (str-cat ?*output-directory*
                         (sub-string 2 (str-length ?uri) ?uri)))

  (if (or (not (tcl/b "file" "exists" ?target))
          (> (tcl/l "file" "mtime" ?source) (tcl/l "file" "mtime" ?target)))
   then
     (run-process "python3"
                  "tools/sam/samparser.py" ?source
                  "|" "xsltproc"
                  "--stringparam" "date" ?date
                  "tools/stylesheets/article.xsl" "-"
                  "|" "xsltproc"
                  "--output" ?target "tools/stylesheets/main.xsl" "-")))

(deffunction compare-post (?a ?b)
  (<= (str-compare (fact-slot-value ?a uri)
                   (fact-slot-value ?b uri))
      0))

(defrule collect-posts
  (exists (post))
 =>
  (bind ?posts (find-all-facts ((?f post)) TRUE))
  (assert (posts (sort compare-post ?posts))))

(defrule generate-archive-html
  (posts $?posts)
 =>
  (bind ?xml (tcl-new-string-obj "<posts>" -1))
  (foreach ?post ?posts
    (tcl-append-to-obj ?xml
                       (format-string "<post>
  <title>%s</title>
  <creation-date>%s</creation-date>
  <uri>%s</uri>
</post>
"
                                      (tcl/s "regsub"
                                             "-all"
                                             "&"
                                             (fact-slot-value ?post title)
                                             "&amp;")
                                      (fact-slot-value ?post creation-date)
                                      (fact-slot-value ?post uri))
                       -1))
  (tcl-append-to-obj ?xml "</posts>" -1)
  (with-process (create$ "xsltproc"
                         "tools/stylesheets/archive.xsl" "-"
                         "|" "xsltproc"
                         "--output" (str-cat ?*output-directory*
                                             "blog/archive.html")
                         "--stringparam" "title" "Archive"
                         "tools/stylesheets/main.xsl" "-")
                (create$ format-out (tcl-get-string ?xml))
                /stdin/))

(defrule generate-home-html
  (posts $?posts)
 =>
  (bind ?xml (tcl-new-string-obj "<posts>" -1))
  (foreach ?post (subseq$ ?posts 1 10)
    (tcl-append-to-obj ?xml
                       (format-string "<post>
  <title>%s</title>
  <creation-date>%s</creation-date>
  <uri>%s</uri>
</post>
"
                                      (tcl/s "string" "map" "& &amp;"
                                             (fact-slot-value ?post title))
                                      (fact-slot-value ?post creation-date)
                                      (fact-slot-value ?post uri))
                       -1))
  (tcl-append-to-obj ?xml "</posts>" -1)
  (with-process (create$ "xsltproc"
                         "tools/stylesheets/home.xsl" "-"
                         "|" "xsltproc"
                         "--output" (str-cat ?*output-directory*
                                             "index.html")
                         "--stringparam" "title" "dram.me"
                         "tools/stylesheets/main.xsl" "-")
                (create$ format-out (tcl-get-string ?xml))
                /stdin/))

(defrule find-page-sources
 =>
  (foreach ?file (with-process (create$ "find"
                                        ?*page-directory* "-name" "*.sam")
                               (create$ read-lines)
                               /stdout/)
    (assert (page (str-cat ?file)
                  (str-cat (sub-string (str-length ?*page-directory*)
                                       (- (str-length ?file) 4)
                                       ?file)
                           ".html")))))

(defrule generate-page-html
  (page ?source ?uri)
 =>
  (bind ?target (str-cat ?*output-directory*
                         (sub-string 2 (str-length ?uri) ?uri)))

  (if (or (not (tcl/b "file" "exists" ?target))
          (> (tcl/l "file" "mtime" ?source) (tcl/l "file" "mtime" ?target)))
   then
     (run-process "python3"
                  "tools/sam/samparser.py" ?source
                  "|" "xsltproc"
                  "tools/stylesheets/article.xsl" "-"
                  "|" "xsltproc"
                  "--output" ?target "tools/stylesheets/main.xsl" "-")))

;;; END OF RULES

(reset)

(run)

(exit)
