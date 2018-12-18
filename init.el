(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(setq package-list '(exec-path-from-shell ggtags company clang-format))

(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))

(require 'ido)
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(setq ido-use-filename-at-point 'guess)
(setq ido-create-new-buffer 'always)
(ido-mode t)

(tool-bar-mode -1)
(menu-bar-mode -1)
(show-paren-mode 1)
(column-number-mode 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq ring-bell-function 'ignore)
(setq-default indent-tabs-mode nil)

(global-set-key (kbd "M-*") 'pop-tag-mark)
(global-font-lock-mode 0)

;; (require 'magit)
;; (global-set-key (kbd "C-x g") 'magit-status)

(add-hook 'after-init-hook 'global-company-mode)

(require 'exec-path-from-shell)
(exec-path-from-shell-copy-env "SSH_AGENT_PID")
(exec-path-from-shell-copy-env "SSH_AUTH_SOCK")
(exec-path-from-shell-copy-env "PATH")

(require 'ggtags)
(add-hook 'c-mode-common-hook
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode 'asm-mode 'python-mode)
              (ggtags-mode 1))))

(global-set-key [f2] 'clang-format-buffer)
(define-key ggtags-mode-map [f3] 'ggtags-find-reference)
(define-key ggtags-mode-map [f4] 'ggtags-find-file)
(define-key ggtags-mode-map [f5] 'ggtags-update-tags)
(define-key ggtags-mode-map [f6] 'ggtags-create-tags)

(setq esp-tagsfile-base "tags")

(defun esp-find-tagsfile ()
  (interactive)
  (let* ((tagsfile (locate-dominating-file default-directory esp-tagsfile-base)))
    (if (not tagsfile)
	(progn
	  (message "Can't find dominating tagsfile")
	  (let ((vc-root (vc-root-dir)))
	    (if vc-root
		(progn
		  (message "Found vc root: %s" vc-root)
		  (concat vc-root esp-tagsfile-base))
	      (concat default-directory esp-tagsfile-base))))
      (let ((tagsfile-final (concat tagsfile esp-tagsfile-base)))
	
	(message "Found dominating tagsfile: %s" tagsfile-final)
	(concat tagsfile esp-tagsfile-base)))))

(defun esp-build-tags ()
  (interactive)
  (let* ((tagsfile (esp-find-tagsfile))
	 (default-directory (file-name-directory tagsfile)))
    (shell-command "/usr/local/bin/ctags -e -R")))

(defun esp-dirname (filename)
  ;; If the last character is a "/", strip it before taking
  ;; file-name-directory. Otherwise, just take file-name-directory.
  ;; This always brings us up one directory level, like dirname in bash.
  (let ((filename-last-char (substring filename -1 nil)))
    (if (string= filename-last-char "/")
	(file-name-directory (substring filename 0 -1))
      (file-name-directory filename))))

(defun esp-basename (filename)
  ;; Like basename in bash.
  (let ((filename-last-char (substring filename -1 nil)))
    (if (string= filename-last-char "/")
	(file-name-nondirectory (substring filename 0 -1))
      (file-name-nondirectory filename))))

(defun esp-rename-shell ()
  (interactive)
  (rename-buffer (concat "shell<" (esp-basename default-directory) ">") 't))

(defun esp-rename-term ()
  (rename-buffer (concat "term<" (esp-basename default-directory) ">") 't))

(add-hook 'dirtrack-directory-change-hook 'esp-rename-term)

(defadvice xref-find-definitions (before c-tag-file activate)
  (let ((tagsfile (esp-find-tagsfile)))
    (unless (file-exists-p tagsfile)
      (let ((default-directory (file-name-directory tagsfile)))
	(shell-command "/usr/local/bin/ctags -e -R")))
    (ignore-errors
      (visit-tags-table tagsfile))))

(defun esp-find-project-base ()
  (interactive)
  (let* ((tagsfile (esp-find-tagsfile)))
    (file-name-directory tagsfile)))

;; (defun ggrip (&optional regexp)
;;   (interactive)
;;   (vc-git-grep (or regexp (thing-at-point 'symbol)) "" (esp-find-project-base)))


(defun copy-buffer-file-name ()
  "Puts the file name of the current buffer (or the current directory,
if the buffer isn't visiting a file) onto the kill ring, so that
it can be retrieved with \\[yank], or by another program."
  (interactive)
  (let ((fn (or
             (buffer-file-name (current-buffer))
             ;; Perhaps the buffer isn't visiting a file at all.  In
             ;; that case, let's return the directory.
             (expand-file-name default-directory))))
    (when (null fn)
      (error "Buffer doesn't appear to be associated with any file or directory."))
    (kill-new fn)
    (message "%s" fn)
    fn))

(when (display-graphic-p)
  (set-background-color "#FFFFEE"))

(defun esp-ansi-term ()
  (interactive)
  (ansi-term "/bin/bash"))

(defun esp-fresh-terminal ()
  (interactive)
  (select-frame (make-frame))
  (esp-ansi-term))

;; Display ido results vertically, rather than horizontally
(setq ido-decorations (quote ("\n-> " "" "\n   " "\n   ..." "[" "]" " [No match]" " [Matched]" " [Not readable]" " [Too big]" " [Confirm]")))
(list-buffers)

(defun esp/term-switcher ()
  (interactive)
  (switch-to-buffer
   (ido-completing-read
    "Terminals: "
    (delq nil (mapcar (lambda (buf)
                        (with-current-buffer buf
                          (if (eq major-mode 'term-mode)
                              (progn
                                (rename-buffer
                                 (concat "term<" (esp-basename default-directory) ">") 't)))))
                      (buffer-list))))))
(global-set-key (kbd "C-x t") 'esp/term-switcher)
(global-set-key [f8] 'esp-ansi-term)
(global-set-key [f9] 'esp-fresh-terminal)

;;
;; This next little bit makes find-file-at-point work with ido-mode.
;;

(defvar esp-ido-find-file-line-number nil
  "Variable to hold line number for ido-find-file, when used on file at point.")

(defadvice ido-file-internal (before
                              ido-file-internal-store-line-number
                              (method &optional fallback default prompt item initial switch-cmd)
                              activate)
  (unless item
    (setq item 'file))
  (when (and (eq item 'file)
             (or ido-use-url-at-point ido-use-filename-at-point))
    (let (fn)
      (require 'ffap)
      (cond
       ((and ido-use-filename-at-point
             (setq fn (with-no-warnings
                        (if (eq ido-use-filename-at-point 'guess)
                            (ffap-guesser)
                          (ffap-string-at-point))))
             (not (string-match "\\`http:/" fn)))
        ;; If we're here, we know ido is going to hop to file at point
        ;; manually, so we have to save our line number, if it exists.
        (let* ((string (ffap-string-at-point))
               (name (or (condition-case nil
                             (and (not (string-match "//" string)) ; foo.com://bar
                                  (substitute-in-file-name string))
                           (error nil))
                         string))
               (line-number-string 
                (and (string-match ":[0-9]+" name)
                     (substring name (1+ (match-beginning 0)) (match-end 0))))
               (line-number
                (and line-number-string
                     (string-to-number line-number-string))))
          (if (and line-number (> line-number 0))
              ;; Save our line number
              (setq esp-ido-find-file-line-number line-number)
            (setq esp-ido-find-file-line-number nil)))
        )))))

(defadvice ido-file-internal (after
                              ido-file-internal-goto-line-number
                              (method &optional fallback default prompt item initial switch-cmd)
                              activate)
  (with-no-warnings
    (when esp-ido-find-file-line-number
      (goto-line esp-ido-find-file-line-number)
      (setq esp-ido-find-file-line-number nil))))

(when (display-graphic-p)
  (set-background-color "#FFFFEE"))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (clang-format company ggtags exec-path-from-shell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

