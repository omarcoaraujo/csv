--// Constants
local COMMA = ","
local QUOTE = '"'

local LF = "\n"
local CR = "\r"
local BOM = "\239\187\191"

--// Types
export type record = { [string]: string }
export type document = { headers: { string }, records: { record } }

--// Functions
local function fail(message: string)
	error(message, 0)
end

local function line_of(text: string, index: number)
	local _, breaks = text:sub(1, index - 1):gsub(LF, "")
	return breaks + 1
end

local function read_quoted(text: string, index: number)
	local chunks = {} :: { string }
	local position = index + 1

	while true do
		local quote_at = text:find(QUOTE, position, true)
		if not quote_at then return fail(`unterminated quote starting at line {line_of(text, index)}`) end

		table.insert(chunks, text:sub(position, quote_at - 1))
		if text:sub(quote_at + 1, quote_at + 1) ~= QUOTE then return table.concat(chunks), quote_at + 1 end

		table.insert(chunks, QUOTE)
		position = quote_at + 2
	end
end

local function read_plain(text: string, index: number)
	local stop = text:find('[,"\r\n]', index) or #text + 1

	if text:sub(stop, stop) == QUOTE then
		return fail(`unexpected quote inside an unquoted field at line {line_of(text, stop)}`)
	end

	return text:sub(index, stop - 1), stop
end

local function read_field(text: string, index: number)
	if text:sub(index, index) == QUOTE then return read_quoted(text, index) end
	return read_plain(text, index)
end

local function skip_line_break(text: string, index: number)
	local character = text:sub(index, index)

	if character == "" then return index end
	if character == LF then return index + 1 end
	if character ~= CR then fail(`unexpected character after closing quote at line {line_of(text, index)}`) end

	if text:sub(index + 1, index + 1) == LF then return index + 2 end
	return index + 1
end

local function read_rows(text: string): ({ { string } }, { number })
	local rows = {} :: { { string } }
	local lines = {} :: { number }

	local line = 1
	local index = 1

	if text:sub(1, #BOM) == BOM then index = #BOM + 1 end
	while index <= #text do
		local row = {} :: { string }
		local start = index

		while true do
			local field

			field, index = read_field(text, index)
			table.insert(row, field)

			if text:sub(index, index) ~= COMMA then break end
			index += 1
		end

		local blank = #row == 1 and index == start
		index = skip_line_break(text, index)

		if not blank then
			table.insert(rows, row)
			table.insert(lines, line)
		end

		local _, breaks = text:sub(start, index - 1):gsub(LF, "")
		line += breaks
	end

	return rows, lines
end

local function check_headers(headers: { string })
	if #headers == 0 then fail "missing header row" end
	local seen = {}

	for _, header in headers do
		if seen[header] then fail(`duplicate header "{header}"`) end
		seen[header] = true
	end
end

local function quote_field(field: string, single_column: boolean)
	if field == "" and single_column then return '""' end
	if not field:find '[,"\r\n]' then return field end

	local escaped = field:gsub(QUOTE, '""')
	return `"{escaped}"`
end

local function encode_row(values: { string }, single_column: boolean)
	local fields = {} :: { string }

	for _, value in values do
		table.insert(fields, quote_field(value, single_column))
	end

	return table.concat(fields, COMMA)
end

local function parse(text: string)
	local rows, lines = read_rows(text)
	local headers = table.remove(rows, 1)
	if not headers then fail "missing header row" end

	check_headers(assert(headers))
	local records = {} :: { record }

	for number, row in rows do
		if #row ~= #headers then fail(`line {lines[number + 1]}: expected {#headers} fields, got {#row}`) end
		local record = {}

		for position, header in headers do
			record[header] = row[position]
		end

		table.insert(records, record)
	end

	return { headers = headers, records = records }
end

local function encode(data: document)
	check_headers(data.headers)

	local single_column = #data.headers == 1
	local lines = { encode_row(data.headers, single_column) }

	for number, record in data.records do
		local values = {} :: { string }

		for _, header in data.headers do
			local value = (record :: { [string]: any })[header]

			if type(value) ~= "string" then
				fail(`record {number}: column "{header}" must be a string, got {typeof(value)}`)
			end

			table.insert(values, value)
		end

		table.insert(lines, encode_row(values, single_column))
	end

	return table.concat(lines, LF) .. LF
end

--// End
return table.freeze {
	parse = parse,
	encode = encode,
}
