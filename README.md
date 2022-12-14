# deepl-translate.el

## DeepL Obtaining an authentication key for the API
To use DeepL from Emacs, use the API; you need an authentication key to use the API.

First, access the official website.
[DeepL](https://www.deepl.com/translator)

At the top of the site you will see "API".
Select "Free Registration" to complete your account registration, and an API key will be issued.

## Install
* request is required, so install it with `M-x package-install request` etc.
* Load this code file from init.el and assign deepl-translate to the appropriate key bindings. In addition, set the API key
```emacs-lisp
(load-file "/path/to/deepl-tranlate.el")
(global-set-key (kbd "C-c t") 'deepl-translate)
(setq deepl-auth-key "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
```
## Install with el-get
* The configuration in leaf.el is as follows
```emacs-lisp
(leaf deepl-translate
 :elget minorugh/deepl-translate
 :bind ("C-c t" . deepl-translate)
 :custom (deepl-auth-key "xxxxxxxxxx-xxxxxx-xxxxxx-xxxx-xxxx-xxxxxxxxxx")
```

## Usage
* Select the region you want to translate and use the key bindings you set, or `M-x deepl-translate`
* The result of the translation appears in the minibuffer. Also, the same content is copied to the clipboard

