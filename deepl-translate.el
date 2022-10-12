;;; deepl-translate.el --- Emacs deepl client -*- lexical-binding: t; -*-

;; Copyright (C) 2022 by Minoru Yamada
;; This script is a modification of Satoshi Imai's deepl.pl so that it can be used with el-get.
;; URL: https://gist.github.com/masatoi/ec90d49331e40983427025f8167d01ee
;; URL: https://github.com/minorugh/deepl-translate
;; Version: 1.0
;; Package-Requires: ((emacs "27.1") (request "0.3.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;;; Usage
;;; Select the region you want to translate and set key bindings, or M-x deepl-translate
;;; The result of the translation will appear in the minibuffer.  Also, the same content is copied to the clipboard

;;; Code:

(require 'request)
(defvar deepl-auth-key) ;;; Set this variable to the key issued by deepl
(defvar deepl-confirmation-threshold 3000)
(defvar deepl-endpoint "api-free.deepl.com") ;;; For paid version api.deepl.com

(cl-defun confirm-send-long-string (&key retry)
  (let ((send-it-p
         (read-from-minibuffer
          (if retry
              "Please answer with \"yes\" or \"no\". [yes/no]: "
            (format "It's over %S characters, do you really want to send it? [yes/no]: "
                    deepl-confirmation-threshold)))))
    (cond ((equal send-it-p "yes") t)
          ((equal send-it-p "no") nil)
          (t (confirm-send-long-string :retry t)))))

(cl-defun deepl-translate-internal (text source-lang target-lang success-callback)
  (when (and (> (length text) deepl-confirmation-threshold)
             (not (confirm-send-long-string)))
    (cl-return-from deepl-translate-internal))

  (request (format "https://%s/v2/translate" deepl-endpoint)
		   :type "POST"
		   :data `(("auth_key" . ,deepl-auth-key)
				   ("text" . ,text)
				   ("source_lang" . ,source-lang)
				   ("target_lang" . ,target-lang))
		   :parser 'json-read
		   :success success-callback))

(cl-defun deepl--output-to-messages (&key data &allow-other-keys)
  (let ((translated-text (cdr (assoc 'text (aref (cdr (assoc 'translations data)) 0)))))
    (kill-new translated-text)
    (message translated-text)))

(defun deepl-ej (start end)
  (interactive "r")
  (let ((region (buffer-substring start end)))
    (deepl-translate-internal region "EN" "JA" #'deepl--output-to-messages)))

(defun deepl-je (start end)
  (interactive "r")
  (let ((region (buffer-substring start end)))
    (deepl-translate-internal region "JA" "EN" #'deepl--output-to-messages)))

(defun ja-char-p (char)
  (or (<= #x3041 char #x309f) ; hiragana
	  (<= #x30a1 char #x30ff) ; katakana
	  (<= #x4e01 char #x9faf) ; kanji
	  ))

(defun ja-string-p (str)
  (>= (cl-count-if #'ja-char-p str) 3))


;;;###autoload
(defun deepl-translate (start end)
  (interactive "r")
  (let ((region (buffer-substring start end)))
    (if (ja-string-p region)
        (deepl-translate-internal region "JA" "EN" #'deepl--output-to-messages)
      (deepl-translate-internal region "EN" "JA" #'deepl--output-to-messages))))


(provide 'deepl-translate.el)
;;; deepl-translate.el ends here
