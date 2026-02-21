.PHONY: ocr-check

ocr-check:
	/usr/bin/swiftc tools/ocr_corpus_check.swift Services/ParsingService.swift -framework PDFKit -o /tmp/ocr_corpus_check
	/tmp/ocr_corpus_check
