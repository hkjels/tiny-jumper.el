;;; tiny-jumper.el --- Jump and highlight lines around point -*- lexical-binding: t; -*-

;; Author: Henrik Kjerringvåg <henrik@kjerringvag.no>
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: navigation, convenience
;; URL: https://github.com/hkjels/tiny-jumper.el

;;; Commentary:

;; Tiny Jumper is a minor mode that highlights a configurable number of lines
;; above and below point and provides movement commands to jump by that number
;; of lines.  The span can be dynamically adjusted (e.g., using Meta + mouse wheel).

;;; Code:

(defgroup tiny-jumper nil
  "Jump and highlight lines around point."
  :group 'convenience)

(defcustom tiny-jumper-persist t
  "If non-nil, highlights persist until the next command.
If nil, highlights will appear only briefly when span is adjusted or a jump is performed."
  :type 'boolean
  :group 'tiny-jumper)

(defcustom tiny-jumper-blink-timeout 0.5
  "How long should lines be highlighted if they are not persistently highlighted."
  :type 'number
  :group 'tiny-jumper)

(defface tiny-jumper-highlight-face
  '((t :inherit hl-line))
  "Face used to highlight context lines in `tiny-jumper-mode`."
  :group 'tiny-jumper)

(defvar tiny-jumper-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<M-mouse-4>") #'tiny-jumper-increase-span)
    (define-key map (kbd "<M-mouse-5>") #'tiny-jumper-decrease-span)
    (define-key map (kbd "M-n") #'tiny-jumper-jump-next)
    (define-key map (kbd "M-p") #'tiny-jumper-jump-prev)
    map)
  "Keymap for `tiny-jumper-mode`.")

(defvar-local tiny-jumper--overlays nil
  "List of active overlays used for highlighting.")

(defvar-local tiny-jumper-span 2
  "Number of lines above and below point to highlight.")

(defun tiny-jumper--clear-overlays ()
  "Remove all active tiny-jumper overlays."
  (when tiny-jumper--overlays
    (mapc #'delete-overlay tiny-jumper--overlays)
    (setq tiny-jumper--overlays nil)))

(defun tiny-jumper--highlight ()
  "Highlight lines around point based on `tiny-jumper-span`."
  (tiny-jumper--clear-overlays)
  (let ((inhibit-modification-hooks t))
    (dolist (offset (list (* tiny-jumper-span -1) tiny-jumper-span))
      (save-excursion
        (unless (= offset 0)
          (forward-line offset)
          (let* ((start (line-beginning-position))
                 (end (line-end-position))
                 (pad-len (max 0 (- (window-width)
                                    (save-excursion
                                      (goto-char end)
                                      (current-column)))))
                 (padding (propertize (make-string pad-len ?\s)
                                      'face 'tiny-jumper-highlight-face)))
            (let ((ov (make-overlay start end)))
              (overlay-put ov 'face 'tiny-jumper-highlight-face)
              (overlay-put ov 'after-string padding)
              (push ov tiny-jumper--overlays)))
          (goto-char (point)))))
    (unless tiny-jumper-persist
      (run-at-time tiny-jumper-blink-timeout nil #'tiny-jumper--clear-overlays))))

(defun tiny-jumper--post-command ()
  "Hook to run after each command to update highlighting."
  (when tiny-jumper-persist
    (tiny-jumper--highlight)))

(defun tiny-jumper-increase-span ()
  "Increase the context span."
  (interactive)
  (setq tiny-jumper-span (1+ tiny-jumper-span))
  (tiny-jumper--highlight))

(defun tiny-jumper-decrease-span ()
  "Decrease the context span (not below 0)."
  (interactive)
  (setq tiny-jumper-span (max 0 (1- tiny-jumper-span)))
  (tiny-jumper--highlight))

(defun tiny-jumper-jump-next ()
  "Jump down by `tiny-jumper-span` lines without changing column."
  (interactive)
  (let ((col (current-column)))
    (forward-line tiny-jumper-span)
    (move-to-column col))
  (tiny-jumper--highlight))

(defun tiny-jumper-jump-prev ()
  "Jump up by `tiny-jumper-span` lines without changing column."
  (interactive)
  (let ((col (current-column)))
    (forward-line (- tiny-jumper-span))
    (move-to-column col))
  (tiny-jumper--highlight))

;;;###autoload
(define-minor-mode tiny-jumper-mode
  "Minor mode to highlight lines around point and jump by span."
  :lighter " TJ"
  :keymap tiny-jumper-mode-map
  :group 'tiny-jumper
  (if tiny-jumper-mode
      (progn
        (add-hook 'post-command-hook #'tiny-jumper--post-command nil t)
        (tiny-jumper--highlight))
    (remove-hook 'post-command-hook #'tiny-jumper--post-command t)
    (tiny-jumper--clear-overlays)))

(provide 'tiny-jumper)

;;; tiny-jumper.el ends here
