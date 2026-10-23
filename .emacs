(when (< emacs-major-version 27)
  (package-initialize))
(setq debug-on-error t)
(setq large-file-warning-threshold 100000000) ;;warn if size >100MB
(setq password-cache-expiry nil) ;never forget passwd(tramp)

;; initial height and width
(when (display-graphic-p)
  ;; width:chars, height:lines, left/top:pixels
  (setq default-frame-alist '((width . 90) (height . 40) (left . 600) (top . 30))
        initial-frame-alist nil))
;;"fbounup symbol": return t if the symbol has an object in it's function
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(setq scroll-margin 6
      scroll-conservatively 10000)

(add-to-list 'load-path "/backup/emacs.d/") ; yasnippets etc.

(column-number-mode 1) ;display line number below
(save-place-mode 1) ; emacs25.1+, goto last place where u previously visit
(delete-selection-mode 1) ;replace selected text when typing
(global-auto-revert-mode 1) ;keep buffers automatically(polling every 5s) up-to-date
(setq auto-revert-remote-files nil); but not the remote files

(electric-pair-mode 1)  ;emacs24+
(fido-mode 1)
(fset 'yes-or-no-p 'y-or-n-p)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(desktop-save-mode 1) ;save sessions
(dolist (mode '(dired-mode fundamental-mode))
  (add-to-list 'desktop-modes-not-to-save mode))

;;Recent opened files
(recentf-mode 1) ;recent opened files
(setq recentf-max-saved-items 36)

;; '/usr/share/emacs/site-lisp/default.el' may override this
(setq frame-title-format '(buffer-file-name "%f" (dired-directory dired-directory "%b"))) ;full file path

(setq backup-directory-alist '(("." . "~/.emacs.d/backups/")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save/" t)))

(global-set-key (kbd "C-z") 'set-mark-command)
(global-set-key (kbd "M-/") 'hippie-expand)
(global-set-key [f5] 'revert-buffer)
(global-set-key [f12] 'recentf-open-files)
(global-unset-key (kbd "C-x C-z")) ;;suspend frame

;; TAB
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4) 

(when (eq system-type 'windows-nt)
  (setq vc-handled-backends nil)) ;Version control.  Cos load file in git dir will cause error. But how to handle?

;; ibuffer, emacs 22+
(global-set-key (kbd "C-x C-b") 'ibuffer)
(setq ibuffer-saved-filter-groups
      '(("home"
         ("Org" (or (mode . org-mode) (filename . "OrgMode")))
         ("LaTeX" (or (mode . latex-mode) (filename . "\*.tex")))
         ("GO"  (mode . go-mode))
         ("Py"  (mode . python-mode))
         ("TXT" (mode . text-mode))
         ("Web Dev" (or (mode . html-mode)(mode . css-mode)(mode . nxhtml-mode)))
         ("emacs-config" (or (filename . ".emacs.d") (filename . "emacs-config")))
         ;; ("Subversion" (name . "\*svn"))
         ("Help" (or (name . "\*Help\*")(name . "\*Apropos\*")(name . "\*info\*"))))))
(add-hook 'ibuffer-mode-hook
          '(lambda ()
           (ibuffer-switch-to-saved-filter-groups "home")))

;;; Org-mode
(add-hook 'org-mode-hook 'turn-on-visual-line-mode) ; more readable for word wrap
(add-hook 'org-mode-hook 'org-indent-mode) ;cleaner outline view

;; coding
;; Donnot set-selection-coding-system utf-16-le, causing leading non-char when coping in win
;; (prefer-coding-system 'utf-8)
;; (set-default-coding-systems 'utf-8)
;; (set-terminal-coding-system 'utf-8)
;; (set-keyboard-coding-system 'utf-8)

;; Theme: "tsdh-dark" "tango-dark"
(condition-case nil
    (load-theme 'tango-dark t)
  (error (message "Warning: tango-dark theme not found")))

;; Set default font. (Move cursor to font)M-x describe-char
(cond
 ((string-equal system-type "windows-nt") ; Microsoft Windows
  (when (member "Consolas" (font-family-list))
    (set-frame-font "Consolas-12" t t)))
 ((string-equal system-type "darwin") ; macOS
  (when (member "Menlo" (font-family-list))
    (set-frame-font "Menlo-12" t t)))
 ((string-equal system-type "gnu/linux") ; linux
  (when (member "DejaVu Sans Mono" (font-family-list))
    (set-frame-font "DejaVu Sans Mono-12" t t))))

;; Set Chinese Char font
(when (eq system-type 'windows-nt)
  (set-fontset-font t 'han (font-spec :family "Sarasa Mono SC" :size 12.5)))

;; Transpose lines
(when (>= emacs-major-version 29)
  (keymap-global-set "M-<up>" (lambda () (interactive) (forward-line -1) (transpose-lines 1) (forward-line -2)))
  (keymap-global-set "M-<down>" (lambda () (interactive) (forward-line 1) (transpose-lines 1) (forward-line -1))))

;;Tramp in Windows
;;Install putty first
(when (eq system-type 'windows-nt)
  (modify-coding-system-alist 'process "plink" 'utf-8-unix)
  (setq tramp-default-method "plink"
        tramp-completion-without-shell-p t)
  (setq tramp-verbose 10)
  (setq tramp-debug-buffer t)
  (let ((path (getenv "PATH"))
        (plink (expand-file-name "PuTTY" (getenv "ProgramFiles"))))
    (setenv "PATH" (concat plink path-separator path)))
  ;; (add-to-list 'exec-path "C:/Program Files/PuTTY/")
  (add-to-list 'exec-path (expand-file-name "PuTTY" (getenv "ProgramFiles"))))

;; ---------------- snippets ----------------------
;; Proxy
;; To test: M-x eww then google.com, https://google.com
(defun toggle-proxy ()
  "Toggle http/https proxy"
  (interactive)
  (when (eq system-type 'windows-nt)  ;both http and https works
    (if url-proxy-services
        (setq url-proxy-services nil)
      (let ((port (read-string "set the port or use the default 10809: " nil nil "10809")))
        (setq url-proxy-services (list (cons "http" (concat "127.0.0.1:" port ))
                                       (cons "https" (concat "127.0.0.1:" port ))))
        (message "win's proxy is: %s " url-proxy-services))))
  (when (eq system-type 'gnu/linux) ; http's ok, not the https, use proxychains???
    (if (eq url-gateway-method 'native)
        (let ((port (read-string "Linux: set the port or use the default 1081: " nil nil "1081")))
          (setq url-gateway-method 'socks)
          (setq socks-server (list "Default server" "127.0.0.1" port 5))
          (message "linux's proxy 127.0.0.1:%s." port))
      (setq url-gateway-method 'native)
      (message "url-gateway-method native"))))

;; Delete leading whitespace from each line in selected region
(defun delete-leading-whitespace (start end)
  (interactive "*r")
  (replace-regexp "^[ \t]+" "" nil start end))

;; ---------------- end snippets ------------------

;; ================================================================
;; The followings need to use use-package
;; (setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
;;                          ("melpa" . "https://melpa.org/packages/")))

(setq package-archives '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
                         ("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))

;; use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
;; setting use-package
(eval-when-compile (require 'use-package))

;;================ company ================
(use-package company
  :ensure t
  :config
  ;;(global-company-mode) 
  ;; Optionally enable completion-as-you-type behavior.
  (setq company-idle-delay 0)
  (setq company-minimum-prefix-length 1))

;;================ yasnippet ================
(use-package yasnippet  ; Optional for go - provides snippet support.
  :ensure t
  :config
  (when (not (eq system-type 'windows-nt))
    (setq yas-snippet-dirs '("/backup/emacs.d/yas-snippets/")))
  (yas-global-mode 1)) ;better globally

;;================ go ================
;; gopls + lsp-ui + company + yasnippet -------
;; 1. install go, gopls(no need for lsp)
;; 2. go install golang.org/x/tools/gopls@latest
;; 3. add ~/go/bin to ~/.profile (otherwise 'Command "gopls" is not present on the path' error)

(use-package go-mode
  :ensure t
  :commands go-mode)

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook (go-mode . lsp-deferred))

;; Set up before-save hooks to format buffer and add/delete imports.
;; Make sure you don't have other gofmt/goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

(use-package lsp-ui  ; Optional - provides fancier overlays.
  :ensure t
  :commands lsp-ui-mode)

;;---------------------------------latex---------------------------------
;;Requirement: Tex Live(recommended)
(use-package auctex
  :defer t
  :ensure t
  :config
  (setq Tex-auto-save t)
  (setq Tex-parse-self t)
  (setq-default TeX-master nil) ; query for master file
  (setq-default TeX-engine 'xetex)) ; default engine

;; Used with AUCTeX to speedup insertion of environment and math templates
;; Also, you can do it with yasnippet
(use-package cdlatex
  :ensure t
  :config
  (add-hook 'LaTeX-mode-hook 'turn-on-cdlatex)   ; with AUCTeX LaTeX mode
  (add-hook 'latex-mode-hook 'turn-on-cdlatex)   ; with Emacs latex mode
  (add-hook 'LaTeX-mode-hook 'company-mode)   ; Very useful
  (add-hook 'latex-mode-hook 'company-mode)   ; 
  (setq cdlatex-paired-parens "$[{(")) ; Default is "$[{", cos like (0,1])
;;---------------------------------End latex------------------------------


