.PHONY: export
export:
	@echo exporting json
	cue export json.cue
	@echo exporting dupe
	cue export dup.cue
	@echo exporting check
	cue export check.cue
	@echo exporting schema
	cue export schema.cue

.PHONY: eval
eval:
	@echo evalin json
	cue eval json.cue
	@echo evalin dupe
	cue eval dup.cue
	@echo evalin check
	cue eval check.cue
	@echo evalin schema
	cue eval schema.cue

.PHONY: eval-bad
eval-bad:
	cue eval dup_bad.cue

.PHONY: schema
schema:
	cue export schema.cue

.PHONY: eval-order
eval-order:
	cue eval -i order.cue

.PHONY: fold
fold:
	cue export fold.cue

.PHONY: types
types:
	cue eval types.cue

.PHONY: bottom
bottom:
	cue eval -i bottom.cue

.PHONY: numbers
numbers:
	cue eval -i numbers.cue

.PHONY: string-lit
string-lit:
	cue export stringlit.cue