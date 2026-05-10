;;; deepl-translate.el --- Deepl translate configurations. -*- lexical-binding: t -*-

;; Copyright (C) 2026 Minoru Yamada and Claude (Anthropic)
;; Author: Minoru Yamada <minorugh@gmail.com>
;; URL: https://github.com/minorugh/deeple-translate
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (request "0.3.0"))
;; Keywords: deepl, translate, versioning

;;; Commentary:
;;; Code:
;; (setq debug-on-error t)

(require 'request)

(defvar deepl-auth-key) ; この変数にdeeplから発行されるキーを設定する
(defvar deepl-confirmation-threshold 3000
  "Character count threshold above which the user is asked to confirm before sending.")
(defvar deepl-endpoint "api-free.deepl.com"
  "DeepL API host.  Use \"api-free.deepl.com\" for the free plan.") ; 無料版は api-free.deepl.com

(cl-defun confirm-send-long-string (&key retry)
  "Ask the user to confirm sending a long string.
Return t if confirmed, nil otherwise.
RETRY non-nil means the prompt is repeated after an invalid answer."
  (let ((send-it-p
         (read-from-minibuffer
          (if retry
              "Please answer with \"yes\" or \"no\". [yes/no]: "
            (format "It's over %S characters, do you really want to send it? [yes/no]: "
                    deepl-confirmation-threshold)))))
    (cond ((equal send-it-p "yes") t)
          ((equal send-it-p "no") nil)
          (t (confirm-send-long-string :retry t)))))

;; 2026-03-10 DeepL API 仕様変更に対応
;; 認証方式を POST ボディ (auth_key) から Authorization ヘッダーに変更
(cl-defun deepl-translate-internal (text source-lang target-lang success-callback)
  "Send TEXT to the DeepL API translating from SOURCE-LANG to TARGET-LANG.
Call SUCCESS-CALLBACK with the parsed JSON response on success.
Prompts for confirmation if TEXT exceeds `deepl-confirmation-threshold'."
  (when (and (> (length text) deepl-confirmation-threshold)
             (not (confirm-send-long-string)))
    (cl-return-from deepl-translate-internal))

  (request (format "https://%s/v2/translate" deepl-endpoint)
    :type "POST"
    :headers `(("Authorization" . ,(format "DeepL-Auth-Key %s" deepl-auth-key)))
    :data `(("text" . ,text)
            ("source_lang" . ,source-lang)
            ("target_lang" . ,target-lang))
    :parser 'json-read
    :success success-callback))

(cl-defun deepl--output-to-messages (&key data &allow-other-keys)
  "Callback for `request': extract translated text from DATA,copy it to the kill ring, and display it as a message."
  (let ((translated-text (cdr (assoc 'text (aref (cdr (assoc 'translations data)) 0)))))
    (setq inhibit-message nil)
    (kill-new translated-text)
    (message translated-text)))

;;;###autoload
(defun deepl-ej (start end)
  "Translate the region from START to END from English to Japanese via DeepL.
Result is shown in the echo area and added to the kill ring."
(interactive "r")
  (let ((region (buffer-substring start end)))
    (deepl-translate-internal region "EN" "JA" #'deepl--output-to-messages)))

;;;###autoload
(defun deepl-je (start end)
  "Translate the region from START to END from Japanese to English via DeepL.
Result is shown in the echo area and added to the kill ring."
(interactive "r")
  (let ((region (buffer-substring start end)))
    (deepl-translate-internal region "JA" "EN" #'deepl--output-to-messages)))

(defun ja-char-p (char)
  "Return non-nil if CHAR is a Japanese hiragana, katakana, or kanji character."
  (or (<= #x3041 char #x309f) ; hiragana
      (<= #x30a1 char #x30ff) ; katakana
      (<= #x4e01 char #x9faf) ; kanji
      ))

(defun ja-string-p (str)
  "Return non-nil if STR contain at least 3 Japanese characters."
  (>= (cl-count-if #'ja-char-p str) 3))

;;;###autoload
(defun deepl-translate (start end)
  "Translate the region from START to END via DeepL.
auto-detecting the language direction.
Japanese input is translated to English; anything else to Japanese."
(interactive "r")
  (let ((region (buffer-substring start end)))
    (if (ja-string-p region)
        (deepl-translate-internal region "JA" "EN" #'deepl--output-to-messages)
      (deepl-translate-internal region "EN" "JA" #'deepl--output-to-messages))))


(provide 'deepl-translate)
;; Local Variables:
;; byte-compile-warnings: (not free-vars)
;; End:
;;; deepl-translate.el ends here
