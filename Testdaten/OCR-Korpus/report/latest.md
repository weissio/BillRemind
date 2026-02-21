# OCR Corpus Report

- Generated: 2026-02-21T15:45:26Z
- Cases: 9/9 passed (100.0%)
- Fields: 81/81 passed (100.0%)

## Case Details

### invoice_01_stadtwerke_style - PASS
- Source: `rechnung/01_stadtwerke_rechnung_style.pdf`
- Document type expected/actual: `invoice` / `invoice`

- [OK] document_type: expected=`invoice` actual=`invoice`
- [OK] vendor_name: expected=`STADTWERKE MAINSTADT GMBH` actual=`STADTWERKE MAINSTADT GMBH`
- [OK] payment_recipient: expected=`STADTWERKE MAINSTADT GMBH` actual=`STADTWERKE MAINSTADT GMBH`
- [OK] amount_value: expected=`162.27` actual=`162.27`
- [OK] category: expected=`WOHNEN` actual=`WOHNEN`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`open` actual=`open`
- [OK] invoice_number: expected=`SW-2026-0217` actual=`SW-2026-0217`
- [OK] iban: expected=`DE12500105175407324931` actual=`DE12500105175407324931`

### invoice_02_versicherung_style - PASS
- Source: `rechnung/02_versicherung_rechnung_style.pdf`
- Document type expected/actual: `invoice` / `invoice`

- [OK] document_type: expected=`invoice` actual=`invoice`
- [OK] vendor_name: expected=`SICHERHEIT & LEBEN VERSICHERUNG AG` actual=`SICHERHEIT & LEBEN VERSICHERUNG AG`
- [OK] payment_recipient: expected=`SICHERHEIT & LEBEN VERSICHERUNG AG` actual=`SICHERHEIT & LEBEN VERSICHERUNG AG`
- [OK] amount_value: expected=`50.00` actual=`50.00`
- [OK] category: expected=`VERSICHERUNG` actual=`VERSICHERUNG`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`open` actual=`open`
- [OK] invoice_number: expected=`VG-2026-0301` actual=`VG-2026-0301`
- [OK] iban: expected=`DE18700202700013441290` actual=`DE18700202700013441290`

### invoice_03_produktkauf_style - PASS
- Source: `rechnung/03_produktkauf_rechnung_style.pdf`
- Document type expected/actual: `invoice` / `invoice`

- [OK] document_type: expected=`invoice` actual=`invoice`
- [OK] vendor_name: expected=`TECHSHOP24 HANDEL GMBH` actual=`TECHSHOP24 HANDEL GMBH`
- [OK] payment_recipient: expected=`TECHSHOP24 HANDEL GMBH` actual=`TECHSHOP24 HANDEL GMBH`
- [OK] amount_value: expected=`148.50` actual=`148.50`
- [OK] category: expected=`SONSTIGES` actual=`SONSTIGES`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`open` actual=`open`
- [OK] invoice_number: expected=`PK-2026-1884` actual=`PK-2026-1884`
- [OK] iban: expected=`DE77860555921012334455` actual=`DE77860555921012334455`

### receipt_01_rewe - PASS
- Source: `kassenbon/01_rewe_kassenbon.pdf`
- Document type expected/actual: `receipt` / `receipt`

- [OK] document_type: expected=`receipt` actual=`receipt`
- [OK] vendor_name: expected=`REWE MARKT GMBH` actual=`REWE MARKT GMBH`
- [OK] payment_recipient: expected=`REWE MARKT GMBH` actual=`REWE MARKT GMBH`
- [OK] amount_value: expected=`27.84` actual=`27.84`
- [OK] category: expected=`LEBENSMITTEL` actual=`LEBENSMITTEL`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`paid` actual=`paid`
- [OK] invoice_number: expected=`null` actual=`null`
- [OK] iban: expected=`null` actual=`null`

### receipt_02_aral - PASS
- Source: `kassenbon/02_aral_kassenbon.pdf`
- Document type expected/actual: `receipt` / `receipt`

- [OK] document_type: expected=`receipt` actual=`receipt`
- [OK] vendor_name: expected=`ARAL TANKSTELLE` actual=`ARAL TANKSTELLE`
- [OK] payment_recipient: expected=`ARAL TANKSTELLE` actual=`ARAL TANKSTELLE`
- [OK] amount_value: expected=`64.12` actual=`64.12`
- [OK] category: expected=`MOBILITÄT` actual=`MOBILITÄT`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`paid` actual=`paid`
- [OK] invoice_number: expected=`null` actual=`null`
- [OK] iban: expected=`null` actual=`null`

### invoice_04_streaming_abo_txt - PASS
- Source: `rechnung/04_streaming_abo_rechnung.txt`
- Document type expected/actual: `invoice` / `invoice`

- [OK] document_type: expected=`invoice` actual=`invoice`
- [OK] vendor_name: expected=`STREAMFLIX DIGITAL SERVICES GMBH` actual=`STREAMFLIX DIGITAL SERVICES GMBH`
- [OK] payment_recipient: expected=`STREAMFLIX DIGITAL SERVICES GMBH` actual=`STREAMFLIX DIGITAL SERVICES GMBH`
- [OK] amount_value: expected=`15.99` actual=`15.99`
- [OK] category: expected=`ABOS` actual=`ABOS`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`open` actual=`open`
- [OK] invoice_number: expected=`ABO-2026-1001` actual=`ABO-2026-1001`
- [OK] iban: expected=`DE44500105175407321122` actual=`DE44500105175407321122`

### invoice_05_apotheke_txt - PASS
- Source: `rechnung/05_apotheke_rechnung.txt`
- Document type expected/actual: `invoice` / `invoice`

- [OK] document_type: expected=`invoice` actual=`invoice`
- [OK] vendor_name: expected=`APOTHEKE AM MARKT GMBH` actual=`APOTHEKE AM MARKT GMBH`
- [OK] payment_recipient: expected=`APOTHEKE AM MARKT GMBH` actual=`APOTHEKE AM MARKT GMBH`
- [OK] amount_value: expected=`35.40` actual=`35.40`
- [OK] category: expected=`SONSTIGES` actual=`SONSTIGES`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`open` actual=`open`
- [OK] invoice_number: expected=`AP-2026-7788` actual=`AP-2026-7788`
- [OK] iban: expected=`DE90500105175407329876` actual=`DE90500105175407329876`

### receipt_03_dm_txt - PASS
- Source: `kassenbon/03_dm_kassenbon.txt`
- Document type expected/actual: `receipt` / `receipt`

- [OK] document_type: expected=`receipt` actual=`receipt`
- [OK] vendor_name: expected=`DM-DROGERIE MARKT GMBH + CO. KG` actual=`DM-DROGERIE MARKT GMBH + CO. KG`
- [OK] payment_recipient: expected=`DM-DROGERIE MARKT GMBH + CO. KG` actual=`DM-DROGERIE MARKT GMBH + CO. KG`
- [OK] amount_value: expected=`18.46` actual=`18.46`
- [OK] category: expected=`SONSTIGES` actual=`SONSTIGES`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`paid` actual=`paid`
- [OK] invoice_number: expected=`null` actual=`null`
- [OK] iban: expected=`null` actual=`null`

### receipt_04_lidl_txt - PASS
- Source: `kassenbon/04_lidl_kassenbon.txt`
- Document type expected/actual: `receipt` / `receipt`

- [OK] document_type: expected=`receipt` actual=`receipt`
- [OK] vendor_name: expected=`LIDL VERTRIEB GMBH & CO. KG` actual=`LIDL VERTRIEB GMBH & CO. KG`
- [OK] payment_recipient: expected=`LIDL VERTRIEB GMBH & CO. KG` actual=`LIDL VERTRIEB GMBH & CO. KG`
- [OK] amount_value: expected=`9.73` actual=`9.73`
- [OK] category: expected=`LEBENSMITTEL` actual=`LEBENSMITTEL`
- [OK] due_date: expected=`null` actual=`null`
- [OK] status_suggestion: expected=`paid` actual=`paid`
- [OK] invoice_number: expected=`null` actual=`null`
- [OK] iban: expected=`null` actual=`null`
