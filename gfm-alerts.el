;;; gfm-alerts.el --- Faces for alerts in GitHub Flavored Markdown  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 Edward Minnix III
;;
;; Author: Edward Minnix III <egregius313@gmail.com>
;; Maintainer: Edward Minnix III <egregius313@gmail.com>
;; Created: October 25, 2025
;; Modified: October 25, 2025
;; Version: 0.0.1
;; Keywords: faces
;; Homepage: https://github.com/egregius313/gfm-alerts
;; Package-Requires: ((emacs "25.1") (dash "2.20") (yasnippet "0.8.0"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;; Provides syntax highlighting for the [!NOTE] style alerts found in GitHub Flavored Markdown.
;;
;;
;;; Code:
(eval-when-compile
  (require 'cl-lib)
  (require 'dash)
  (require 'rx))

(defgroup gfm-alerts ()
  "Highlight [!IMPORTANT] and similar keywords."
  :group 'font-lock-extra-types)

(defface gfm-alerts
  '((t (:bold t :foreground "#198032")))
  "Base face for highlighting [!IMPORTANT] and similar keywords."
  :group 'gfm-alerts)

(defconst gfm-alerts-org-rx
  (rx line-start
      (* blank)
      (group-n 1
        "[!"
        (group-n 2 (or "CAUTION" "IMPORTANT" "NOTE" "TIP" "WARNING"))
        "]")
      line-end)
  "Regexp for recognizing alerts.")

(defconst gfm-alerts-md-rx
  (rx line-start
      (* blank)
      ?>
      (+ space)
      (group-n 1
        "[!"
        (group-n 2 (or "CAUTION" "IMPORTANT" "NOTE" "TIP" "WARNING"))
        "]")
      line-end)
  "Regexp for recognizing alerts.")

(defvar gfm-alerts--keywords
  `((,(lambda (bound) (gfm-alerts--search bound))
     (0 (gfm-alerts--get-face) prepend t))))

(defvar gfm-alerts--colors nil)
(defvar gfm-alerts--faces nil)

(defmacro gfm-alerts--define-alert (alert-name color)
  (let ((face-name (->> alert-name (format "gfm-alerts--%s-face") downcase intern))
        (face-def `((t (:bold t :foreground ,color)))))
    `(progn
       (add-to-list 'gfm-alerts--colors '(,alert-name . ,color) t)
       (add-to-list 'gfm-alerts--faces '(,alert-name . ,face-name))
       (defface ,face-name
         ',face-def
         ,(format "Face for highlighting the [!%s] alert." alert-name)
         :group 'gfm-alerts))))

(gfm-alerts--define-alert "CAUTION" "#c32733")
(gfm-alerts--define-alert "IMPORTANT" "#8056d1")
(gfm-alerts--define-alert "NOTE" "#0968d8")
(gfm-alerts--define-alert "TIP" "#198032")
(gfm-alerts--define-alert "WARNING" "#9b6500")

(defun gfm-alerts--start-of-quote ()
  (let ((previous-line (save-excursion
                         (forward-line -1)
                         (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))
    (cond
     ((derived-mode-p 'markdown-mode)
      (not (string-prefix-p ">" previous-line)))
     ((derived-mode-p 'org-mode)
      (string-prefix-p "#+begin_quote" previous-line t)))))

(defun gfm-alerts--search (&optional bound backward)
  (let ((regexp (cond
                 ((derived-mode-p 'markdown-mode) gfm-alerts-md-rx)
                 ((derived-mode-p 'org-mode) gfm-alerts-org-rx))))
    (cl-block nil
      (while (funcall (if backward #'re-search-backward #'re-search-forward) regexp bound t)
        (cond
         ((gfm-alerts--start-of-quote)
          (cl-return t))
         ((and bound (funcall (if backward #'<= #'>=) (point) bound))
          (cl-return nil)))))))

(defun gfm-alerts--get-face ()
  (let* ((keyword (match-string 2))
         (face (cdr (assoc keyword gfm-alerts--faces))))
    face))

;;;###autoload
(define-minor-mode gfm-alerts-mode
  "Highlight [!IMPORTANT] and similar keywords in quote blocks."
  :group 'gfm-alerts
  (if gfm-alerts-mode
      (font-lock-add-keywords nil gfm-alerts--keywords t)
    (font-lock-remove-keywords nil gfm-alerts--keywords)))

(provide 'gfm-alerts)
;;; gfm-alerts.el ends here
