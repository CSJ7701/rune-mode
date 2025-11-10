;;; rune-mode.el --- Major mode for Rune configuration files -*- lexical-binding: t; -*-

;; Author: Christian Johnson
;; Version: 0.4
;; Keywords: languages, configuration

;;; Commentary:
;; Major mode for Rune configuration files.
;; Features syntax highlighting, comment syntax, and indentation for
;; nested blocks and arrays.

;;; Code:

(defvar rune-mode-indent-offset 2
  "Indentation offset for `rune-mode'.")

(defvar rune-mode-font-lock-keywords
  `(
    ;; @directives - highlight the @ keyword itself
    (,(rx bol
          (* space)
          (group "@" (+ (any "a-zA-Z_"))))
     (1 font-lock-preprocessor-face))
    ;; section headers: foo:
    (,(rx bol (* space) (group (+ (any "a-zA-Z0-9_-"))) ":")
     (1 font-lock-keyword-face))
    ;; block terminator
    (,(rx symbol-start "end" symbol-end)
     (0 font-lock-keyword-face))
    ;; numeric constants
    (,(rx symbol-start (group (1+ digit)) symbol-end)
     (1 font-lock-constant-face))
    ;; regex literal (r"...")
    (,(rx symbol-start "r" "\"" (0+ (not (any "\""))) "\"")
     (0 font-lock-string-face))
    ;; strings
    (,(rx "\"" (0+ (not (any "\""))) "\"")
     (0 font-lock-string-face))
    ))

(defvar rune-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; “# …” comments
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table for `rune-mode'.")

(defun rune--previous-indentation-level ()
  "Return indentation level of previous non-empty line."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp))
                (or (looking-at-p "^[ \t]*$")
		    (looking-at-p "^[ \t]*#")))
      (forward-line -1))
    (current-indentation)))

(defun rune--previous-line-opens-block-p ()
  "Return non-nil if previous non-empty line opens a block (ends with : or [)."
  (save-excursion
    (forward-line -1)
    ;; Skip blank lines and comments
    (while (and (not (bobp))
		(or (looking-at-p "^[ \t]*$")
		    (looking-at-p "^[ \t]*#")))
      (forward-line -1))
    ;; Check if line ends with : or [ (ignoring trailing whitespace/comments
    (end-of-line)
    (skip-chars-backward " \t")
    (when (search-backward "#" (line-beginning-position) t)
      (skip-chars-backward " \t"))
    (or (eq (char-before) ?:)
	(eq (char-before) ?\[))))

(defun rune-calculate-indentation ()
  "Compute indentation for current line."
  (save-excursion
    (beginning-of-line)
    (let ((indent (rune--previous-indentation-level)))
      (cond
       ;; Dedent for 'end' or closing ']'
       ((looking-at (rx (* space) (or (seq "end" symbol-end) "]")))
        (max 0 (- indent rune-mode-indent-offset)))

       ;; If previous line ends with ':' or '[', indent
       ((rune--previous-line-opens-block-p)
        (+ indent rune-mode-indent-offset))

       ;; Otherwise keep same indentation
       (t indent)))))

(defun rune-indent-line ()
  "Indent current line for Rune mode. Indents from ':' to 'end' and from '[' to ']'."
  (interactive)
  (let ((indent (rune-calculate-indentation))
        (offset (- (current-column) (current-indentation))))
    (indent-line-to indent)
    (when (> offset 0) (forward-char offset))))

;;;###autoload
(define-derived-mode rune-mode prog-mode "Rune"
  "Major mode for editing Rune configuration files."
  :syntax-table rune-mode-syntax-table
  (setq-local font-lock-defaults '(rune-mode-font-lock-keywords))
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local indent-line-function #'rune-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rune\\'" . rune-mode))

(provide 'rune-mode)
;;; rune-mode.el ends here
