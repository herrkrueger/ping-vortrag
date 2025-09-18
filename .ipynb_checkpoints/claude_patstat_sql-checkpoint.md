# PATSTAT Python Library: ORM vs Raw SQL Guide

## Two Approaches to Query PATSTAT Data

### 1. ORM Approach (Recommended)
```python
# Setup
from epo.tipdata.patstat import PatstatClient
from epo.tipdata.patstat.database.models import TLS201_APPLN, TLS206_PERSON
from sqlalchemy import func

patstat = PatstatClient()
db = patstat.orm()

# Query
q = db.query(TLS201_APPLN.appln_id, TLS201_APPLN.appln_auth).\
    filter(TLS201_APPLN.appln_filing_year == 2010)

# Convert to DataFrame (no pandas import needed)
df = patstat.df(q)
```

**Advantages:**
- Type safety and IDE support
- Automatic DataFrame conversion via `patstat.df()`
- No manual pandas import required
- Less error-prone for complex queries
- Built-in SQLAlchemy functionality

### 2. Raw SQL Approach
```python
# Query
res = patstat.sql_query("""
SELECT appln_id, appln_auth
FROM tls201_appln
WHERE appln_filing_year = 2010
""")

# Manual conversion to DataFrame
import pandas as pd
df = pd.DataFrame(res)  # res is list of dictionaries
```

**When to use:** Simple queries or when you prefer pure SQL syntax.

## Essential SQLAlchemy Functions

### Aggregation
```python
func.count(), func.sum(), func.avg(), func.max(), func.min()
func.count().distinct()  # Distinct count
```

### String Operations
```python
column.like('%pattern%')      # Pattern matching
column.ilike('%AI%')          # Case-insensitive
column.contains('blockchain') # String containment
func.lower(), func.upper()    # Case conversion
```

### Date Operations
```python
func.extract('year', date_column)   # Extract year/month/day
column.between(start, end)          # Date ranges
func.current_date()                 # Current date
```

### Logical Operations
```python
from sqlalchemy import and_, or_, not_
and_(condition1, condition2)
column.in_(['US', 'EP', 'WO'])
```

### Conditional Logic
```python
from sqlalchemy import case
case(
    (table.granted == 'Y', 'Granted'),
    (table.granted == 'N', 'Rejected'),
    else_='Pending'
)
```

### Window Functions
```python
func.rank().over(order_by=column.desc())
func.row_number().over(partition_by=col1, order_by=col2)
```

## Key Takeaways

1. **ORM is more efficient** for complex queries and data analysis
2. **Raw SQL requires manual DataFrame conversion** with `pd.DataFrame()`
3. **patstat.df()** automatically handles pandas conversion in ORM
4. **SQLAlchemy functions** provide powerful analytical capabilities
5. **Type safety** and IDE support make ORM less error-prone

## Quick Reference: DataFrame Conversion

| Approach | Data Return | DataFrame Conversion |
|----------|-------------|---------------------|
| ORM | SQLAlchemy Query | `patstat.df(query)` |
| Raw SQL | List of Dicts | `pd.DataFrame(result)` |

---
*For PATSTAT training sessions - efficient patent data analysis with Python*