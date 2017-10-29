(defglobal ?*page-directory* = "_sources/pages/")
(defglobal ?*post-directory* = "_sources/posts/")
(defglobal ?*output-directory* = "./")

;;;
;;; BEGIN OF HELPER FUNCTION DEFINIATIONS
;;;

(deffunction tcl ($?c) (tcl-eval-ex (tcl-merge ?c) -1 /))
(deffunction string (?f $?a) (format nil ?f (expand$ ?a)))

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
  (foreach ?file (progn (tcl "glob" "-path" ?*post-directory* "*.sam")
                        (tcl-split-list (tcl-get-string-result)))
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
                                (progn (tcl "string" "map" "- /" ?date)
                                       (tcl-get-string-result))
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

  (if (tcl-expr-boolean
       (string "![file exists %s] || [file mtime %s] > [file mtime %s]"
               ?target ?source ?target))
   then (tcl "exec" "xsltproc"
             "--stringparam" "date" ?date
             "tools/stylesheets/article.xsl" "-"
             "|" "xsltproc"
             "--output" ?target "tools/stylesheets/main.xsl" "-"
             "<<" (progn (tcl "parse-sam-file" ?source)
                         (tcl-get-string-result)))))

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
                       (string "<post>
  <title>%s</title>
  <creation-date>%s</creation-date>
  <uri>%s</uri>
</post>
"
                               (progn (tcl "string" "map" "& &amp;"
                                           (fact-slot-value ?post title))
                                      (tcl-get-string-result))
                               (fact-slot-value ?post creation-date)
                               (fact-slot-value ?post uri))
                       -1))
  (tcl-append-to-obj ?xml "</posts>" -1)
  (tcl "exec" "xsltproc"
       "tools/stylesheets/archive.xsl" "-"
       "|" "xsltproc"
       "--output" (str-cat ?*output-directory* "blog/archive.html")
       "--stringparam" "title" "Archive" "tools/stylesheets/main.xsl" "-"
       "<<" (tcl-get-string ?xml)))

(defrule generate-home-html
  (posts $?posts)
 =>
  (bind ?xml (tcl-new-string-obj "<posts>" -1))
  (foreach ?post (subseq$ ?posts 1 10)
    (tcl-append-to-obj ?xml
                       (string "<post>
  <title>%s</title>
  <creation-date>%s</creation-date>
  <uri>%s</uri>
</post>
"
                               (progn (tcl "string" "map" "& &amp;"
                                           (fact-slot-value ?post title))
                                      (tcl-get-string-result))
                               (fact-slot-value ?post creation-date)
                               (fact-slot-value ?post uri))
                       -1))
  (tcl-append-to-obj ?xml "</posts>" -1)
  (tcl "exec" "xsltproc"
       "tools/stylesheets/home.xsl" "-"
       "|" "xsltproc"
       "--output" (str-cat ?*output-directory* "index.html")
       "--stringparam" "title" "dram.me" "tools/stylesheets/main.xsl" "-"
       "<<" (tcl-get-string ?xml)))

(defrule find-page-sources
 =>
  (foreach ?file (progn (tcl "exec" "find" ?*page-directory* "-name" "*.sam")
                        (tcl-split-list (tcl-get-string-result)))
    (assert (page ?file
                  (str-cat (sub-string (str-length ?*page-directory*)
                                       (- (str-length ?file) 4)
                                       ?file)
                           ".html")))))

(defrule generate-page-html
  (page ?source ?uri)
 =>
  (bind ?target (str-cat ?*output-directory*
                         (sub-string 2 (str-length ?uri) ?uri)))

  (if (tcl-expr-boolean
       (string "![file exists %s] || [file mtime %s] > [file mtime %s]"
               ?target ?source ?target))
   then (tcl "exec" "xsltproc"
             "tools/stylesheets/article.xsl" "-"
             "|" "xsltproc"
             "--output" ?target "tools/stylesheets/main.xsl" "-"
             "<<" (progn (tcl "parse-sam-file" ?source)
                         (tcl-get-string-result)))))

;;; END OF RULES
