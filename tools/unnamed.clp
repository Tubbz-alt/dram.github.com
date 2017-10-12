;;; Generated by clips-unnamed-library:
;;;     compile-library /home/dramw/clips/dram.me/tools call-with-input-file call-with-input-process call-with-output-process create-directory create-temporary-directory read-contents read-lines remove-directory replace-substring run-process

;;; BEGIN DEFINITION of call-with-input-file

(deffunction call-with-input-file (?path ?function ?rest-arguments)
  (bind ?f (gensym*))
  (open ?path ?f)
  (bind ?result (funcall ?function ?f (expand$ ?rest-arguments)))
  (close ?f)
  ?result)

;;; END of call-with-input-file


;;; BEGIN DEFINITION of call-with-input-command

(deffunction call-with-input-command (?command
                                      ?function
                                      ?rest-arguments)
  (bind ?f (gensym*))
  (UNNAMED-open-piped-command ?command ?f "r")
  (bind ?result (funcall ?function ?f (expand$ ?rest-arguments)))
  (UNNAMED-close-piped-command ?f)
  ?result)

;;; END of call-with-input-command


;;; BEGIN DEFINITION of call-with-output-command

(deffunction call-with-output-command (?command
                                       ?function
                                       ?rest-arguments)
  (bind ?f (gensym*))
  (UNNAMED-open-piped-command ?command ?f "w")
  (bind ?result (funcall ?function ?f (expand$ ?rest-arguments)))
  (UNNAMED-close-piped-command ?f)
  ?result)

;;; END of call-with-output-command


;;; BEGIN DEFINITION of read-contents

(deffunction read-contents (?f)
  (bind ?result "")
  (while (neq (bind ?line (readline ?f)) EOF)
    (bind ?result (format nil "%s%s%n" ?result ?line)))
  ?result)

;;; END of read-contents


;;; BEGIN DEFINITION of read-lines

(deffunction read-lines (?f)
  (bind ?result (create$))
  (while (neq (bind ?line (readline ?f)) EOF)
    (bind ?result ?result ?line))
  ?result)

;;; END of read-lines


;;; BEGIN DEFINITION of replace-substring

(deffunction replace-substring (?string ?pattern ?replacement)
  (bind ?i (str-index ?pattern ?string))
  (if (or (not ?i)
          (eq ?pattern ""))
   then ?string
   else (str-cat (sub-string 1 (- ?i 1) ?string)
                 ?replacement
                 (replace-substring (sub-string (+ ?i (str-length ?pattern))
                                                (str-length ?string)
                                                ?string)
                                    ?pattern
                                    ?replacement))))

;;; END of replace-substring


;;; BEGIN DEFINITION of leave-message

(deffunction leave-message (?level ?object ?format $?fields)
  (format stderr
          (str-cat "%s %s: " ?format "%n") ?level ?object (expand$ ?fields)))

;;; END of leave-message


;;; BEGIN DEFINITION of escape-shell-string

(deffunction escape-shell-string (?string)
  (str-cat "'" (replace-substring ?string "'" "'\"'\"'") "'"))

;;; END of escape-shell-string


;;; BEGIN DEFINITION of make-command

(deffunction make-command (?program ?arguments $?options)
  (bind ?in-file nil)
  (bind ?out-file nil)

  (bind ?option-length (length$ ?options))
  (bind ?i 1)
  (while (<= ?i ?option-length)
    (switch (nth$ ?i ?options)
      (case -input-from-file
       then (bind ?in-file (nth$ (+ ?i 1) ?options))
            (bind ?i (+ ?i 2)))
      (case -output-to-file
       then (bind ?out-file (nth$ (+ ?i 1) ?options))
            (bind ?i (+ ?i 2)))
      (default
        (leave-message ERROR make-command
                                "invalid option `%s'" (nth$ ?i ?options))
        (return))))

  (bind ?command ?program)
  (foreach ?argument ?arguments
    (bind ?command
      (str-cat ?command " " (escape-shell-string ?argument))))

  (if (neq nil ?in-file)
   then (bind ?command
          (str-cat ?command " <" (escape-shell-string ?in-file))))
  (if (neq nil ?out-file)
   then (bind ?command
          (str-cat ?command " >" (escape-shell-string ?out-file))))

  ?command)

;;; END of make-command


;;; BEGIN DEFINITION of call-with-input-process

(deffunction call-with-input-process (?program
                                      ?arguments
                                      ?function
                                      ?rest-arguments)
  (call-with-input-command (make-command ?program ?arguments)
                                    ?function
                                    ?rest-arguments))

;;; END of call-with-input-process


;;; BEGIN DEFINITION of create-temporary-directory

(deffunction create-temporary-directory (?template)
  (call-with-input-process
      mktemp (create$ -d ?template)
    readline (create$)))

;;; END of create-temporary-directory


;;; BEGIN DEFINITION of call-with-output-process

(deffunction call-with-output-process (?program
                                       ?arguments
                                       ?function
                                       ?rest-arguments)
  (call-with-output-command (make-command ?program
                                                            ?arguments)
                                     ?function
                                     ?rest-arguments))

;;; END of call-with-output-process


;;; BEGIN DEFINITION of run-process

(deffunction run-process (?program ?arguments $?options)
  (system (make-command ?program ?arguments (expand$ ?options))))

;;; END of run-process


;;; BEGIN DEFINITION of create-directory

(deffunction create-directory (?name)
  (run-process "/bin/mkdir" (create$ -p ?name)))

;;; END of create-directory


;;; BEGIN DEFINITION of remove-directory

(deffunction remove-directory (?name)
  (run-process "/bin/rm" (create$ -r ?name)))

;;; END of remove-directory
