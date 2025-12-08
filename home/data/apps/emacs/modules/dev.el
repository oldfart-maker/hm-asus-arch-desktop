(use-package typescript-mode
  :mode "\\.ts\\'")

(use-package python-mode
  :hook (python-mode . eglot-ensure))

(use-package pyvenv
  :config (pyvenv-mode 1))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (when (file-directory-p "~/Documents/Code")
    (setq projectile-project-search-path '("~/Documents/Code")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package request
:ensure t)

(require 'request)
(require 'json)

;; Enable Eglot automatically for certain modes
(add-hook 'python-mode-hook #'eglot-ensure)
