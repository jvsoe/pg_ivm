# pg_ivm key_field feature

## Overview
This document explains the purpose, usage, and implementation of the `key_field` feature in pg_ivm.

## Purpose
The `key_field` feature enables set semantics for IMMVs by designating a single, stable key column. This avoids tuple-multiplicity tracking (such as `__ivm_count__`) and allows deterministic updates and inserts keyed on that column. It is particularly useful for integrations like pg_search, where a dedicated key field is required for indexing and maintenance.

## Catalog and API
- `pg_ivm.h`: Adds `key_field` column to catalog, updates function signatures to carry `key_field`.
- `pg_ivm.c`: `create_immv` SQL-callable function accepts optional `key_field` argument, passes to `ExecCreateImmv`.

## IMMV Creation
- `createas.c`:
  - `validate_key_field()`: Ensures `key_field` is valid (non-empty, present in target list, simple SELECT).
  - `rewriteQueryForIMMV()`: Injects set-semantics logic, prevents __ivm_count__ in set mode.
  - `CreateIndexOnIMMV()`: Creates primary key index on `key_field` using `DefineIndex`.
  - `StoreImmvQuery()`: Persists `key_field` in catalog.

## Maintenance
- `matview.c`:
  - `get_immv_key_field()`: Loads `key_field` from catalog.
  - `IVM_immediate_maintenance()`: Reads `key_field`, sets `set_semantics`, passes to maintenance routines.
  - `apply_delta()`: Uses `set_semantics` to select key column and dispatches to set-semantics maintenance path.
  - `apply_new_delta_set()`: Performs explicit UPDATE+INSERT for set semantics.

## SQL Extension
- `pg_ivm--1.13+keyfield.sql`: Adds `key_field` column and new `create_immv(text, text, text DEFAULT NULL)` signature.
- `pg_ivm--1.13--1.13+keyfield.sql`: Upgrade script for catalog and function.

## Versioning
- `pg_ivm.control`: `default_version = '1.13+keyfield'`.
- `Makefile`: DATA list includes 1.13+keyfield scripts.

## Flow Summary
1. `create_immv` called with optional `key_field`.
2. `validate_key_field()` checks validity.
3. Catalog updated, PK index created.
4. Maintenance routines use `key_field` for set semantics, explicit upsert logic.

## Notes
- Creation-time validation is centralized in `validate_key_field()` during `ExecCreateImmv`.
- Runtime guard remains in maintenance to catch catalog drift or post-create changes.
- Set semantics do not use `__ivm_count__`.

---
This document is intended for public consumption and may evolve with future updates.
