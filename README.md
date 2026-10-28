# csv

CSV parser and encoder for [Luau](https://luau.org). Pure functions on strings: no filesystem, no runtime APIs, so it runs on Lute, Lune and Zune.

## Installation

Add csv to your `pesde.toml`:

```toml
[dependencies]
csv = { name = "omarcoaraujo/csv", version = "^0.1.0" }
```

Then require it:

```luau
local csv = require("@pkg/csv")
```

## Usage

```luau
local data = csv.parse(text)

for _, record in data.records do
	print(record.description, tonumber(record.amount_brl))
end

local text = csv.encode(data)
```

`parse` reads a header row and returns `{ headers, records }`: the header names in file order, and one table per row keyed by header name. Every value is a string, so convert numbers yourself.

`encode` takes the same shape and returns the text. Columns follow `headers`, keys that are not headers are ignored, a field is quoted only when it holds a comma, a double quote or a line break, and the text ends with a single `\n`. In a single-column file an empty value is written as `""`, so it does not turn into a blank line.

## Format

- Fields may be quoted with `"`, and `""` inside quotes is a literal quote
- Quoted fields may hold commas and line breaks (LF or CRLF)
- Line endings can be LF or CRLF, and the final newline is optional
- Empty fields are kept as empty strings
- Blank lines and a leading byte order mark are skipped
- `parse` then `encode` returns the original text when it uses LF and no unneeded quotes

## Errors

Both functions raise a plain message with no traceback position.

| Message | Cause |
|---|---|
| `unterminated quote starting at line N` | A quoted field never closes |
| `line N: expected X fields, got Y` | A row does not match the header |
| `unexpected quote inside an unquoted field at line N` | A `"` in the middle of an unquoted field |
| `unexpected character after closing quote at line N` | Text right after a closing quote |
| `missing header row` | Empty input |
| `duplicate header "name"` | Two columns with the same name |
| `record N: column "name" must be a string, got T` | `encode` got a missing or non-string value |

## Development

```sh
pesde install
lute run tests
stylua --config-path stylua.toml --check lib tests
luau-lsp analyze --platform=standard lib tests
```

## License

MIT
