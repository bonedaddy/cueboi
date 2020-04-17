.PHONY: export
export:
	@echo exporting json
	cue export json.cue
	@echo exporting dupe
	cue export dup.cue
	@echo exporting check
	cue export check.cue

.PHONY: eval
eval:
	@echo evalin json
	cue eval json.cue
	@echo evalin dupe
	cue eval dup.cue
	@echo evalin check
	cue eval check.cue

.PHONY: eval-bad
eval-bad:
	cue eval dup_bad.cue