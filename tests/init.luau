const tint = require "@pkg/tint"
const suites = {
	parse = require "@self/parse",
	encode = require "@self/encode",
} :: { [string]: { [string]: any } }

const function is_test(name: string, value: any)
	return typeof(value) == "function" and name:sub(1, 7) == "should_"
end

const function get_sorted_keys(suite: { [string]: any })
	const keys = {}

	for key, value in suite do
		if is_test(key, value) then table.insert(keys, key) end
	end

	table.sort(keys)
	return keys
end

local total = 0
local failed = 0

for suite_name, suite in suites do
	for _, name in get_sorted_keys(suite) do
		total += 1

		const success, error_message = pcall(suite[name])
		if success then continue end

		failed += 1
		print(`  {tint.red.bold "✗"} {tint.dim(`{suite_name}/{name}`)} {tint.red(error_message)}`)
	end
end

if failed > 0 then error(`\n{tint.red.bold(`✗ {failed}/{total} tests failed!`)}`) end
print(`{tint.green.bold(`✓ {total}/{total}`)} all tests passed! \n`)
