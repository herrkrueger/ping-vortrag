# PATSTAT SQL/ORM Zugriffsmethoden für Claude-Projekte

## PATSTAT Client Setup

```python
from epo.tipdata.patstat import PatstatClient

# Client instantiieren
patstat = PatstatClient(env='PROD')  # oder 'TEST' für Entwicklung

# ORM-Instanz erstellen
db = patstat.orm()
```

## Tabellen-Modelle importieren

```python
from epo.tipdata.patstat.database.models import (
    TLS201_APPLN,           # Anmeldungen
    TLS202_APPLN_TITLE,     # Titel
    TLS206_PERSON,          # Personen/Anmelder
    TLS207_PERS_APPLN,      # Person-Anmeldung Verknüpfung
    TLS224_APPLN_CPC,       # CPC Klassifikationen
    TLS231_INPADOC_LEGAL_EVENT  # Legal Events
)
```

## Basis-Query-Patterns

### 1. Einfache Filter-Queries
```python
# Erteilte EPO-Patente aus 2010
q = db.query(TLS201_APPLN.appln_id, TLS201_APPLN.appln_auth, TLS201_APPLN.appln_nr).\
    filter(TLS201_APPLN.appln_filing_year == 2010,
           TLS201_APPLN.appln_auth == 'EP',
           TLS201_APPLN.granted == 'Y')

# Ergebnis als DataFrame
df = patstat.df(q)
```

### 2. JOIN-Queries mit Klassifikationen
```python
# Anmeldungen mit CPC-Codes
q = db.query(TLS201_APPLN.appln_id, TLS224_APPLN_CPC.cpc_class_symbol).\
    join(TLS224_APPLN_CPC).\
    filter(TLS201_APPLN.appln_filing_year.between(2010, 2015),
           TLS224_APPLN_CPC.cpc_class_symbol.like('Y02E  10/7%'))
```

### 3. Komplexe Multi-Table JOINs
```python
# Anmeldungen mit Anmelder und Titel
q = db.query(TLS201_APPLN.appln_id, TLS206_PERSON.psn_name, TLS202_APPLN_TITLE.appln_title).\
    select_from(TLS201_APPLN).\
    join(TLS207_PERS_APPLN).\
    join(TLS206_PERSON).\
    join(TLS202_APPLN_TITLE).\
    filter(TLS206_PERSON.psn_name == 'CARL ZEISS')
```

### 4. Aggregation und Gruppierung
```python
from sqlalchemy import func

# Top Anmelder nach Anmeldungsanzahl
q = db.query(TLS206_PERSON.psn_name,
             func.count(TLS201_APPLN.appln_id).label('anzahl_anmeldungen')).\
    select_from(TLS206_PERSON).\
    join(TLS207_PERS_APPLN).join(TLS201_APPLN).\
    filter(TLS206_PERSON.person_ctry_code == 'DE').\
    group_by(TLS206_PERSON.psn_name).\
    order_by(func.count(TLS201_APPLN.appln_id).desc())
```

### 5. Legal Events und Gebühren
```python
# Gebührenzahlungen in bestimmten Ländern
q = db.query(TLS206_PERSON.psn_name, TLS231_INPADOC_LEGAL_EVENT.fee_country).\
    select_from(TLS201_APPLN).\
    join(TLS207_PERS_APPLN).join(TLS206_PERSON).join(TLS231_INPADOC_LEGAL_EVENT).\
    filter(TLS231_INPADOC_LEGAL_EVENT.event_code == 'PGFP',
           TLS231_INPADOC_LEGAL_EVENT.fee_country == 'BE').\
    distinct()
```

## Alternative: RAW SQL Queries

```python
# Legacy SQL (Standard)
res = patstat.sql_query("""
SELECT appln_id, appln_auth +appln_nr + appln_kind number, appln_filing_date
FROM tls201_appln
WHERE appln_filing_year = 2010 AND appln_auth ='EP' AND granted = 'Y'
""")

# Standard SQL
res = patstat.sql_query("""
SELECT appln_id, appln_auth, appln_nr FROM tls201_appln
WHERE appln_filing_year = 2010
""", use_legacy_sql=False)
```

## Schema-Exploration

```python
# Verfügbare Tabellen anzeigen
patstat.list_global_tables()
patstat.list_register_tables()

# Schema-Diagramme anzeigen
patstat.global_schema()
patstat.register_schema()
```

## Wichtige Filter-Patterns

```python
# Deutsche Anmeldungen
.filter(TLS201_APPLN.appln_auth == 'DE')

# Nach Anmeldejahr
.filter(TLS201_APPLN.appln_filing_year >= 2020)

# Deutsche NUTS-Codes
.filter(TLS206_PERSON.nuts.like('DE%'))

# Nur Anmelder (keine Erfinder)
.filter(TLS207_PERS_APPLN.applt_seq_nr > 0,
        TLS207_PERS_APPLN.invt_seq_nr == 0)

# CPC-Klassifikation mit Wildcards
.filter(TLS224_APPLN_CPC.cpc_class_symbol.like('Y02E  10/7%'))
```

## Wichtige Tabellen im Überblick

### GLOBAL Tables
```python
'tls201_appln',             # Anmeldungen (Basis-Tabelle)
'tls202_appln_title',       # Anmeldungstitel
'tls203_appln_abstr',       # Anmeldungsabstracts
'tls206_person',            # Personen/Anmelder
'tls207_pers_appln',        # Person-Anmeldung Verknüpfung
'tls209_appln_ipc',         # IPC Klassifikationen
'tls211_pat_publn',         # Patent-Publikationen
'tls212_citation',          # Zitationen
'tls224_appln_cpc',         # CPC Klassifikationen
'tls231_inpadoc_legal_event' # Legal Events
```

### REGISTER Tables
```python
'reg101_appln',             # Register-Anmeldungen
'reg102_pat_publn',         # Register-Publikationen
'reg107_parties',           # Beteiligte Parteien
'reg201_proc_step',         # Verfahrensschritte
'reg301_event_data'         # Event-Daten
```

## Ergebnis-Konvertierung

```python
# Als DataFrame
df = patstat.df(query)

# Als Python-Liste (bei SQL-Queries)
results = patstat.sql_query("SELECT ...")

# Erste N Ergebnisse
query.limit(10)

# Sortierung
query.order_by(TLS201_APPLN.appln_filing_date.desc())
```

## Häufige Use Cases

### Regionale Analyse
```python
# Deutsche Anmelder nach Bundesland
q = db.query(TLS206_PERSON.psn_name, TLS206_PERSON.nuts).\
    join(TLS207_PERS_APPLN).join(TLS201_APPLN).\
    filter(TLS206_PERSON.nuts.like('DE%'),
           TLS206_PERSON.nuts_level == 1)
```

### Technologietrends
```python
# CPC-Klassen über Zeit
q = db.query(TLS201_APPLN.appln_filing_year,
             TLS224_APPLN_CPC.cpc_class_symbol,
             func.count().label('anzahl')).\
    join(TLS224_APPLN_CPC).\
    group_by(TLS201_APPLN.appln_filing_year, TLS224_APPLN_CPC.cpc_class_symbol)
```

### Anmelder-Rankings
```python
# Top-Anmelder nach Land
q = db.query(TLS206_PERSON.psn_name,
             TLS206_PERSON.person_ctry_code,
             func.count(TLS201_APPLN.appln_id).label('patent_count')).\
    select_from(TLS206_PERSON).\
    join(TLS207_PERS_APPLN).join(TLS201_APPLN).\
    filter(TLS207_PERS_APPLN.applt_seq_nr > 0,
           TLS207_PERS_APPLN.invt_seq_nr == 0).\
    group_by(TLS206_PERSON.psn_name, TLS206_PERSON.person_ctry_code).\
    order_by(func.count(TLS201_APPLN.appln_id).desc())
```

## Best Practices

1. **Immer `select_from()` bei komplexen JOINs verwenden**
2. **Filter für Anmelder/Erfinder:** `applt_seq_nr > 0, invt_seq_nr == 0`
3. **NUTS-Level beachten:** Level 0=Land, 1=Bundesland, 2=Regierungsbezirk, 3=Landkreis
4. **CPC-Wildcards:** Beachten Sie Leerzeichen in CPC-Codes (`Y02E  10/7%`)
5. **Performance:** Bei großen Datenmengen `limit()` verwenden
6. **Standardisierte Namen:** `psn_name` statt `person_name` für bessere Ergebnisse