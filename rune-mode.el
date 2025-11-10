;;; rune-mode.el --- Major mode for Rune configuration files -*- lexical-binding: t; -*-

;; Author: CJ
;; Keywords: languages, configuration
;; Version: 0.2

;;; Commentary:
;; Major mode for Rune configuration syntax.
;; Provides syntax highlighting and indentation support.

;;; Code:

(defvar rune-mode-indent-offset 2
  "Indentation offset for `rune-mode'.")

(defvar rune-mode-font-lock-keywords
  `((,@(rx line-start "@" (group (+ (any "a-zA-Z_"))) symbol-end)
     1 font-lock-preprocessor-face)
    (,(rx line-start (group (+ (any "a-zA-Z0-9_-"))) ":")
     1 font-lock-keyword-face)
    (,(rx symbol-start "end" symbol-end)
     0 font-lock-keyword-face)
    (,(rx symbol-start (group (1+ digit)) symbol-end)
     1 font-lock-constant-face)
    (,(rx "\"" (0+ (not (any "\""))) "\"")
     0 font-lock-string-face)))

(defvar rune-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; “# …” comments
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table for `rune-mode'.")

(defun rune-calculate-indentation ()
  "Compute indentation for the current line in Rune mode."
  (save-excursion
    (beginning-of-line)
    (let ((indent 0))
      ;; If current line is 'end', dedent
      (when (looking-at (rx (* space) "end" symbol-end))
        (setq indent (- indent rune-mode-indent-offset)))
      ;; Look upward for previous non-empty line
      (while (and (not (bobp))
                  (progn (forward-line -1)
                         (looking-at-p "^[ \t]*$"))))
      (when (not (bobp))
        (cond
         ;; Previous line ends with ':'
         ((looking-at (rx (* space) (+ (not (any "#"))) ":" (* space) (opt "#" (* any))))
          (setq indent (+ indent rune-mode-indent-offset)))
         ;; Previous line is 'end' (don’t increase indent)
         ((looking-at (rx (* space) "end" symbol-end))
          (setq indent 0))
         ;; Otherwise, use same indentation
         (t (setq indent (current-indentation)))))
      (max 0 indent))))

(defun rune-indent-line ()
  "Indent current line for Rune mode."
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
