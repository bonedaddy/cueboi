.PHONY: vet
vet: vet-bad vet-good

.PHONY: vet-bad
vet-bad:
	cue vet schema.cue data_bad.yaml

.PHONY: vet-good
vet-good:
	cue vet schema.cue data_good.yaml