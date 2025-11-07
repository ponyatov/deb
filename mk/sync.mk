.PHONY: sync
sync:
	rsync -r $(HOME)/metadoc/$(APP)/ doc/
	rsync -r $(HOME)/metadoc/deb/    doc/
