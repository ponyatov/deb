.PHONY: sync
sync:
	rsync -r $(HOME)/metadoc/$(APP)/ doc/
