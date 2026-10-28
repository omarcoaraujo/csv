const csv = require "@lib"
const spec = {} :: { [string]: any }

const function fails(callback: () -> any, expected: string)
	const success, message = pcall(callback)
	assert(not success, `expected an error containing "{expected}"`)
	assert(string.find(tostring(message), expected, 1, true), `wrong error: {message}`)
end

-- encode
function spec.should_encode_header_and_records()
	const data = {
		headers = { "date", "amount_brl" },
		records = { { date = "2026-10-01", amount_brl = "12.50" }, { date = "2026-10-02", amount_brl = "1250.00" } },
	}

	assert(csv.encode(data) == "date,amount_brl\n2026-10-01,12.50\n2026-10-02,1250.00\n")
end

function spec.should_follow_column_order_not_key_order()
	const data = { headers = { "c", "a", "b" }, records = { { a = "1", b = "2", c = "3" } } }
	assert(csv.encode(data) == "c,a,b\n3,1,2\n")
end

function spec.should_encode_header_only()
	assert(csv.encode { headers = { "a", "b" }, records = {} } == "a,b\n")
end

function spec.should_reject_encoding_without_headers()
	fails(function()
		return csv.encode { headers = {}, records = {} }
	end, "missing header row")
end

function spec.should_reject_missing_value()
	fails(function()
		return csv.encode { headers = { "a", "b" }, records = { { a = "1", b = "2" }, { a = "3" } } }
	end, 'record 2: column "b" must be a string, got nil')
end

function spec.should_reject_non_string_value()
	fails(function()
		return csv.encode { headers = { "a" }, records = { { a = 12.5 :: any } } }
	end, 'record 1: column "a" must be a string, got number')
end

function spec.should_ignore_keys_that_are_not_headers()
	const data = { headers = { "a" }, records = { { a = "1", extra = "2" } } }
	assert(csv.encode(data) == "a\n1\n")
end

function spec.should_quote_comma()
	const data = { headers = { "a", "b" }, records = { { a = "1,5", b = "2" } } }
	assert(csv.encode(data) == 'a,b\n"1,5",2\n')
end

function spec.should_double_quotes()
	const data = { headers = { "a" }, records = { { a = 'say "hi"' } } }
	assert(csv.encode(data) == 'a\n"say ""hi"""\n')
end

function spec.should_quote_line_breaks()
	const data = { headers = { "a", "b" }, records = { { a = "one\ntwo", b = "x\r\ny" } } }
	assert(csv.encode(data) == 'a,b\n"one\ntwo","x\r\ny"\n')
end

function spec.should_quote_header_that_needs_it()
	const data = { headers = { "first, name" }, records = { { ["first, name"] = "x" } } }
	assert(csv.encode(data) == '"first, name"\nx\n')
end

function spec.should_not_quote_plain_fields_with_spaces_and_decimals()
	const data = { headers = { "a", "b" }, records = { { a = " x ", b = "5.1859338271045" } } }
	assert(csv.encode(data) == "a,b\n x ,5.1859338271045\n")
end

function spec.should_quote_empty_value_in_a_single_column()
	const data = { headers = { "a" }, records = { { a = "" }, { a = "x" } } }
	assert(csv.encode(data) == 'a\n""\nx\n')
end

function spec.should_reject_duplicate_headers()
	fails(function()
		return csv.encode { headers = { "a", "a" }, records = {} }
	end, 'duplicate header "a"')
end

-- round trips
function spec.should_round_trip_text_with_no_unneeded_quotes()
	const text =
		'date,category,description,amount_brl,type,paid_from\n2026-10-05,food,"Market, ""downtown""",250.00,expense,card\n2026-10-06,rent,"two\nlines",1250.00,expense,\n'
	assert(csv.encode(csv.parse(text)) == text)
end

function spec.should_round_trip_data()
	const data = {
		headers = { "a", "b" },
		records = { { a = "1,2", b = "" }, { a = 'q"q', b = "l1\nl2" }, { a = "", b = "" } },
	}

	const parsed = csv.parse(csv.encode(data))
	assert(#parsed.records == 3)

	for index, record in data.records do
		assert(parsed.records[index].a == record.a)
		assert(parsed.records[index].b == record.b)
	end
end

function spec.should_turn_crlf_into_lf()
	assert(csv.encode(csv.parse "a,b\r\n1,2\r\n") == "a,b\n1,2\n")
end

function spec.should_round_trip_single_column_with_empty_value()
	const text = 'a\n""\nx\n'
	assert(csv.encode(csv.parse(text)) == text)
end

return spec
