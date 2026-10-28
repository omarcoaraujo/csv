# Changelog

## 0.1.0 - 2026-10-27

- Read CSV text into a header list and rows keyed by column name
- Write rows back to CSV text, quoting only the fields that need it
- Quoted fields can hold commas, quotes and line breaks
- Clear errors for an unterminated quote and for rows with the wrong number of fields
