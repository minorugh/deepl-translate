.PHONY: git

git:
	git add -A
	git diff --cached --quiet || git commit -m "auto: $$(date '+%Y-%m-%d %H:%M:%S')"
	git push || true

# Local Variables:
# buffer-read-only: t
# End:
