local csv = require "@lib"
local spec = {} :: { [string]: any }

local function fails(callback: () -> any, expected: string)
	local success, message = pcall(callback)
	assert(not success, `expected an error containing "{expected}"`)
	assert(string.find(tostring(message), expected, 1, true), `wrong error: {message}`)
end

local function same_headers(actual: { string }, expected: { string })
	assert(#actual == #expected, `expected {#expected} columns, got {#actual}`)

	for index, column in expected do
		assert(actual[index] == column, `column {index} is "{actual[index]}", expected "{column}"`)
	end
end

-- shape
function spec.should_return_headers_in_header_order()
	local data = csv.parse "date,category,amount_brl\n2026-10-01,food,12.50\n"
	same_headers(data.headers, { "date", "category", "amount_brl" })
end

function spec.should_key_records_by_header_name()
	local data = csv.parse "date,category,amount_brl\n2026-10-01,food,12.50\n2026-10-02,rent,1250.00\n"

	assert(#data.records == 2)
	assert(data.records[1].date == "2026-10-01")

	assert(data.records[1].amount_brl == "12.50")
	assert(data.records[2].category == "rent")
	assert(data.records[2].amount_brl == "1250.00")
end

function spec.should_keep_decimal_points_as_text()
	local data = csv.parse "rate\n5.1859338271045\n0.10\n"
	assert(data.records[1].rate == "5.1859338271045")
	assert(data.records[2].rate == "0.10")
end

function spec.should_parse_row_shaped_like_the_real_data()
	local text =
		'date,category,description,amount_brl,type,paid_from\n2026-10-05,food,"Market, downtown",250.00,expense,card\n'
	local record = csv.parse(text).records[1]
	assert(record.description == "Market, downtown")

	assert(record.amount_brl == "250.00")
	assert(record.paid_from == "card")
end

function spec.should_return_no_records_for_header_only()
	local data = csv.parse "a,b\n"
	same_headers(data.headers, { "a", "b" })
	assert(#data.records == 0)
end

function spec.should_reject_empty_text()
	fails(function()
		return csv.parse ""
	end, "missing header row")
end

function spec.should_reject_text_with_only_blank_lines()
	fails(function()
		return csv.parse "\n\r\n"
	end, "missing header row")
end

-- line endings
function spec.should_parse_lf()
	local data = csv.parse "a,b\n1,2\n3,4\n"
	assert(#data.records == 2 and data.records[2].b == "4")
end

function spec.should_parse_crlf()
	local data = csv.parse "a,b\r\n1,2\r\n3,4\r\n"
	assert(#data.records == 2)
	assert(data.records[1].b == "2" and data.records[2].a == "3")
end

function spec.should_parse_mixed_line_endings()
	local data = csv.parse "a,b\r\n1,2\n3,4\r\n"
	assert(#data.records == 2 and data.records[1].b == "2")
end

function spec.should_parse_without_trailing_newline()
	local data = csv.parse "a,b\n1,2"
	assert(#data.records == 1 and data.records[1].b == "2")
end

function spec.should_parse_with_trailing_newline()
	local data = csv.parse "a,b\n1,2\n"
	assert(#data.records == 1)
end

function spec.should_skip_blank_lines()
	local data = csv.parse "a,b\n\n1,2\n\n\n3,4\n\n"
	assert(#data.records == 2)
end

function spec.should_ignore_byte_order_mark()
	local data = csv.parse "\239\187\191a,b\n1,2\n"
	same_headers(data.headers, { "a", "b" })
end

-- quotes
function spec.should_parse_quoted_field()
	assert(csv.parse('a\n"hello"\n').records[1].a == "hello")
end

function spec.should_parse_comma_inside_quotes()
	local data = csv.parse 'a,b\n"1,5",2\n'
	assert(data.records[1].a == "1,5" and data.records[1].b == "2")
end

function spec.should_parse_double_quote_inside_quotes()
	local data = csv.parse 'a,b\n"say ""hi""",2\n'
	assert(data.records[1].a == 'say "hi"')
end

function spec.should_parse_field_that_is_only_an_escaped_quote()
	assert(csv.parse('a\n""""\n').records[1].a == '"')
end

function spec.should_parse_lf_inside_quotes()
	local data = csv.parse 'a,b\n"line one\nline two",2\n3,4\n'
	assert(data.records[1].a == "line one\nline two")
	assert(#data.records == 2 and data.records[2].a == "3")
end

function spec.should_parse_crlf_inside_quotes()
	local data = csv.parse 'a,b\r\n"line one\r\nline two",2\r\n'
	assert(data.records[1].a == "line one\r\nline two")
end

function spec.should_parse_quoted_header()
	local data = csv.parse '"first, name",b\n1,2\n'
	assert(data.headers[1] == "first, name")
	assert(data.records[1]["first, name"] == "1")
end

function spec.should_parse_empty_quoted_field_in_a_single_column()
	local data = csv.parse 'a\n""\nx\n'
	assert(#data.records == 2 and data.records[1].a == "")
end

-- empty fields
function spec.should_parse_empty_fields()
	local data = csv.parse "a,b,c\n1,,3\n,,\n"
	assert(data.records[1].b == "")
	assert(data.records[2].a == "" and data.records[2].b == "" and data.records[2].c == "")
end

function spec.should_parse_trailing_comma_at_end_of_text()
	local data = csv.parse "a,b\n1,"
	assert(data.records[1].a == "1" and data.records[1].b == "")
end

function spec.should_keep_spaces_around_fields()
	local data = csv.parse "a,b\n x , y \n"
	assert(data.records[1].a == " x " and data.records[1].b == " y ")
end

-- errors
function spec.should_reject_short_row_with_line_number()
	fails(function()
		return csv.parse "a,b\n1,2\n3\n"
	end, "line 3: expected 2 fields, got 1")
end

function spec.should_reject_long_row()
	fails(function()
		return csv.parse "a,b\n1,2,3\n"
	end, "line 2: expected 2 fields, got 3")
end

function spec.should_count_lines_inside_quotes_in_error()
	fails(function()
		return csv.parse 'a,b\n"x\ny",2\n3\n'
	end, "line 4: expected 2 fields, got 1")
end

function spec.should_reject_unterminated_quote()
	fails(function()
		return csv.parse 'a,b\n"1,2\n'
	end, "unterminated quote starting at line 2")
end

function spec.should_reject_quote_inside_unquoted_field()
	fails(function()
		return csv.parse 'a,b\n1"x,2\n'
	end, "unexpected quote inside an unquoted field at line 2")
end

function spec.should_reject_text_after_closing_quote()
	fails(function()
		return csv.parse 'a,b\n"1"x,2\n'
	end, "unexpected character after closing quote at line 2")
end

function spec.should_reject_duplicate_headers()
	fails(function()
		return csv.parse "a,a\n1,2\n"
	end, 'duplicate header "a"')
end

return spec
