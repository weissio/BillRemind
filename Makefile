# Hinweis fuer Tests:
# xcodebuild serialisiert NICHT zwischen mehreren parallelen Aufrufen am
# selben Projekt — das kann das .xcodeproj-Paket beschaedigen (z. B. wurde
# in einem Vorfall waehrend Release 1.0.4 das ganze BillRemind.xcodeproj/
# Verzeichnis voruebergehend nach b.xcodeproj/ umbenannt). Daher gilt:
#
#   * NICHT zwei xcodebuild-Aufrufe parallel gegen dieses Projekt starten.
#   * In Skripten/CI-Pipelines bitte sequentiell laufen lassen
#     (`make build && make test`, NICHT `make build & make test`).
#   * Falls echte Parallelitaet noetig ist: `flock` davor setzen,
#     z. B. `flock /tmp/billremind-xcodebuild.lock xcodebuild ...`

.PHONY: ocr-check

ocr-check:
	/usr/bin/swiftc tools/ocr_corpus_check.swift Services/ParsingService.swift -framework PDFKit -o /tmp/ocr_corpus_check
	/tmp/ocr_corpus_check
