;;; originally based on: Emacs4CL 0.4.0 <https://github.com/susam/emacs4cl>

;; Customize user interface.
;; get rid of interface elements that cause clutter
(menu-bar-mode 0)

(when (display-graphic-p)
  (tool-bar-mode 0)
  (scroll-bar-mode 0))

(setq inhibit-startup-screen t)

;;;
;; all kind of preferences
(delete-selection-mode 1)


;;;;;;;;;
;; Restoring frame-size
;; When opened from a  windowing system, open emacs with the frame size it was closed with.
;; This code to save and restore frame size when closing/opening emacs
;; from the portacle config files: https://github.com/portacle/emacsd
;; and adapted it for my setup. An emacs lisp file to set the previous frame size
;; will be saved in the user-emacs-directory.
;;
(defun --normalized-frame-parameter (parameter)
  (let ((value (frame-parameter (selected-frame) parameter)))
    (if (number-or-marker-p value) (max value 0) 0)))

(defun save-framegeometry ()
  (let* ((props '(left top width height))
         (values (mapcar '--normalized-frame-parameter props)))
    (with-temp-buffer
        (cl-loop for prop in props
                 for val in values
                 do (insert (format "(add-to-list 'initial-frame-alist '(%s . %d))\n"
                                    prop val)))
        (write-file (concat user-emacs-directory ".frame.el")))))

(defun load-framegeometry ()
  (when (file-exists-p (concat user-emacs-directory ".frame.el"))
    (load-file (concat user-emacs-directory ".frame.el"))))

(when window-system
  (add-hook 'emacs-startup-hook 'load-framegeometry)
  (add-hook 'kill-emacs-hook 'save-framegeometry))
;;

; highlight current line
; (global-hl-line-mode t)

;; Use spaces, not tabs, for indentation.
(setq-default indent-tabs-mode nil)

;; Highlight matching pairs of parentheses.
(setq show-paren-delay 0)
(show-paren-mode)

;; Write customizations to a separate file instead of this file.
;; When we install packages using package-install (coming up soon in a later point),
;; a few customizations are written automatically into the Emacs initialization file (~/.emacs.d/init.el in our case).
;; This has the rather undesirable effect of our carefully handcrafted init.el being meddled by package-install.
;; To be precise, it is the custom package invoked by package-install that intrudes into our Emacs initialization file.
;; To prevent that, we ask custom to write the customizations to a separate file with the following code:
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
; Note that this line of code must occur before the package-install call.

; emacs doesnt load the custom file automatically
(load custom-file t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Enable installation of packages from MELPA.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org"   . "https://orgmode.org/elpa/") t)
;;(add-to-list 'package-archives '("elpa"  . "https://elpa/gnu.org/packages/") t)
(package-initialize)


(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
   (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)



;;;
;; keep everything clean
;; @TODO
;;

;; use meta-arrow keys to move between windows
(windmove-default-keybindings 'meta)
;; ToDO: investigate package buffer-move


;;; Pick a theme.
;;(load-theme 'wombat t)
;;(set-face-background 'default "#111")

;;;
;; modus themes
;; https://protesilaos.com/emacs/modus-themes#h:1af85373-7f81-4c35-af25-afcef490c111
;;; For the built-in themes which cannot use `require':
;; Add all your customizations prior to loading the themes
;;
;;
(unless (package-installed-p 'modus-themes)
  (package-install 'modus-themes))

(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs nil
      modus-themes-region '(bg-only no-extend)
      )
;;
;; Load the theme of your choice:
;;(load-theme 'modus-operandi t) ;; OR
(load-theme 'modus-vivendi t)
(define-key global-map (kbd "<f5>") #'modus-themes-toggle)



;; Install packages.
(dolist (package '(slime paredit rainbow-delimiters))
  (unless (package-installed-p package)
    (package-install package)))

;;-------------------------
;;
;; slime-configuration
;; Configure SBCL as the Lisp program for SLIME.
(add-to-list 'exec-path "/usr/local/bin")
(setq inferior-lisp-program "sbcl")

;; sensible return settings for edditing in the REPL
(add-hook 'slime-repl-mode-hook 'set-slime-repl-return)

(defun set-slime-repl-return ()
  (define-key slime-repl-mode-map (kbd "RET") 'slime-repl-return-at-end)
  (define-key slime-repl-mode-map (kbd "<return>") 'slime-repl-return-at-end))

(defun slime-repl-return-at-end ()
  (interactive)
  (if (<= (point-max) (point))
      (slime-repl-return)
    (slime-repl-newline-and-indent)))


;; Enable Paredit.
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook 'enable-paredit-mode)
(add-hook 'ielm-mode-hook 'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook 'enable-paredit-mode)
(add-hook 'lisp-mode-hook 'enable-paredit-mode)
(add-hook 'slime-repl-mode-hook 'enable-paredit-mode)
(defun override-slime-del-key ()
  (define-key slime-repl-mode-map
    (read-kbd-macro paredit-backward-delete-key) nil))
(add-hook 'slime-repl-mode-hook 'override-slime-del-key)

;; Enable Rainbow Delimiters.
(add-hook 'emacs-lisp-mode-hook 'rainbow-delimiters-mode)
(add-hook 'ielm-mode-hook 'rainbow-delimiters-mode)
(add-hook 'lisp-interaction-mode-hook 'rainbow-delimiters-mode)
(add-hook 'lisp-mode-hook 'rainbow-delimiters-mode)
(add-hook 'slime-repl-mode-hook 'rainbow-delimiters-mode)

;; Customize Rainbow Delimiters.
(require 'rainbow-delimiters)
(set-face-foreground 'rainbow-delimiters-depth-1-face "#c66")  ; red
(set-face-foreground 'rainbow-delimiters-depth-2-face "#6c6")  ; green
(set-face-foreground 'rainbow-delimiters-depth-3-face "#69f")  ; blue
(set-face-foreground 'rainbow-delimiters-depth-4-face "#cc6")  ; yellow
(set-face-foreground 'rainbow-delimiters-depth-5-face "#6cc")  ; cyan
(set-face-foreground 'rainbow-delimiters-depth-6-face "#c6c")  ; magenta
(set-face-foreground 'rainbow-delimiters-depth-7-face "#ccc")  ; light gray
(set-face-foreground 'rainbow-delimiters-depth-8-face "#999")  ; medium gray
(set-face-foreground 'rainbow-delimiters-depth-9-face "#666")  ; dark gray



;;;;;;;;;;;;;;;;;;;;;
;; completion framework
(use-package company
  :ensure t
  :hook ((slime-repl-mode common-lisp-mode emacs-lisp-mode) . company-mode)
  :bind (:map company-active-map
              ("<up>" . (lambda ()
                          (interactive)
                          (company-select-previous)))
              ("<down>" . (lambda ()
			  (interactive)
                          (company-select-next)))
              ("C-p" . (lambda ()
                          (interactive)
                          (company-select-previous)))
              ("C-n" . (lambda ()
			  (interactive)
                          (company-select-next)))
              ("SPC" . (lambda ()
                         (interactive)
                         (company-abort)
                         (insert " ")))
              ("<return>" . nil)
              ("RET" . nil)
              ("<tab>" . company-complete))
  :config
  (setq company-minimum-prefix-length 2
        company-idle-delay 0.1
        company-flx-limit 20))

(use-package slime-company
  :after (slime company)
  :ensure t
  :config
  (setq slime-company-completion 'fuzzy)
  ;; We redefine this function to call SLIME-COMPANY-DOC-MODE in the buffer
  (defun slime-show-description (string package)
    (let ((bufname (slime-buffer-name :description)))
      (slime-with-popup-buffer (bufname :package package
					:connection t
					:select slime-description-autofocus)
	(when (string= bufname "*slime-description*")
	  (with-current-buffer bufname (slime-company-doc-mode)))
	(princ string)
	(goto-char (point-min))))))




;; to use company-mode in all buffers
(add-hook 'after-init-hook 'global-company-mode)
; No delay in showing suggestions.
(setq company-idle-delay 0)
; Show suggestions after entering one character.
(setq company-minimum-prefix-length 1)

;
(slime-setup '(slime-fancy slime-company))

;;;;;;;;;;;;;;;;;;;;;;
;; nicer looking modeline
;;

(use-package all-the-icons
 	:ensure t)
(use-package doom-modeline
 :ensure t
 :init (doom-modeline-mode 1)
 :custom ((doom-modeline-height 12)))

;;;;;;;;;;;;;;;;;;;;;
;; magit
(use-package magit
  :ensure t)


;;;;;;;;;;;;;;;;;;;;
; org mode 

; set variables for each orgmode buffer
(defun jhl/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))




(defun jhl/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-document-title . 2.0)
                  (org-level-1 . 1.75)
                  (org-level-2 . 1.5)
                  (org-level-3 . 1.3)
                  (org-level-4 . 1.1)
                  (org-level-5 . 1.0)
                  (org-level-6 . 1.0)
                  (org-level-7 . 1.0)
                  (org-level-8 . 1.0)))
    (set-face-attribute (car face) nil  :weight 'regular :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))
  
  
(use-package org
  :hook (org-mode . jhl/org-mode-setup)
  :config
  (setq org-ellipsis " ▾")
  (jhl/org-font-setup))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(setq org-hide-emphasis-markers t
      org-pretty-entities t ; special symbols, such as superscript and subscript (x^2 or x_2), /alpha, ...
      )

(defun jhl/org-mode-visual-fill ()
  (setq visual-fill-column-width 96
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . jhl/org-mode-visual-fill))

;;-------------
;; org-babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (lisp . t)))

;; -----
;; structure templates
(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("li" . "src lisp :results value verbatim"))
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))

;; no nagging when C-c C-c evaluating source code blocks
(setq org-confirm-babel-evaluate nil)



;;; misc
;; 
;; now you can switch fonts by calling the functions below
;; of course, these functions need the proper fonts installed.
;; all these functions have a fixed with as default font.
;; for modes that need a variable pitch font set an appropriate hook

(defun font/hack-vera ()
  (interactive)
  (set-face-attribute 'default        nil :font "Hack" :weight 'medium )
  (set-face-attribute 'fixed-pitch    nil :font "Hack" :weight 'medium )
  (set-face-attribute 'variable-pitch nil :font "Bitstream Vera Sans" :weight 'medium ))


(defun font/noto ()
  (interactive)
  (set-face-attribute 'default        nil :font "Noto Mono" :weight 'medium )
  (set-face-attribute 'fixed-pitch    nil :font "Noto Mono" :weight 'medium )
  (set-face-attribute 'variable-pitch nil :font "Noto Sans UI" :weight 'medium ))

(defun font/dejavu ()
  (interactive)
  (set-face-attribute 'default        nil :font "DejaVU Sans Mono" :weight 'medium )
  (set-face-attribute 'fixed-pitch    nil :font "DejaVu Sans Mono" :weight 'medium )
  (set-face-attribute 'variable-pitch nil :font "DejaVu Sans" :weight 'medium ))

(defun font/fira ()
  (interactive)
  (set-face-attribute 'default        nil :font "Fira Mono" :weight 'medium )
  (set-face-attribute 'fixed-pitch    nil :font "Fira Mono" :weight 'medium )
  (set-face-attribute 'variable-pitch nil :font "Fira Sans" :weight 'medium ))

;;(font/dejavu)



;; todo
;; highlight-indentation
;; https://github.com/DarthFennec/highlight-indent-guides
;; https://github.com/antonj/Highlight-Indentation-for-Emacs/
;;
;;
;; (global-org-modern-mode)
