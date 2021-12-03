(require 'org-web-tools)

(defun rofi-org-bookmarks/runn (url)
  (->>
   (org-web-tools--url-as-readable-org url)
   (substring-no-properties)
   (message "foo %s")))
