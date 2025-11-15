local M = {}

local defaults = {}

local is_setup = false

function M.setup(opts)
	if is_setup then
		return
	end

	local function color_add(color, delta)
		local sign = 1
		local d = delta
		if delta < 0 then
			sign = -1
			d = -delta
		end
		local r = bit.rshift(bit.band(color, 0xff0000), 16)
		local g = bit.rshift(bit.band(color, 0xff00), 8)
		local b = bit.band(color, 0xff)
		local dr = bit.rshift(bit.band(d, 0xff0000), 16)
		local dg = bit.rshift(bit.band(d, 0xff00), 8)
		local db = bit.band(d, 0xff)
		r = r + sign * dr
		g = g + sign * dg
		b = b + sign * db
		if r > 255 then
			r = 255
		end
		if r < 0 then
			r = 0
		end
		if g > 255 then
			g = 255
		end
		if g < 0 then
			g = 0
		end
		if b > 255 then
			b = 255
		end
		if b < 0 then
			b = 0
		end
		return bit.lshift(r, 16) + bit.lshift(g, 8) + b
	end

	local function get_bg_fg_color_hex()
		local dim_value = 0x282828
		local hl_normal = vim.api.nvim_get_hl(0, { name = "Normal" })
		if hl_normal then
			-- Convert the integer color code to a hex string
			local bg = hl_normal.bg
			local fg = hl_normal.fg
			local bg_dim = bg
			local fg_dim = fg
			if bg > fg then
				-- light background
				bg_dim = color_add(bg_dim, -dim_value)
				fg_dim = color_add(fg_dim, dim_value)
			else
				bg_dim = color_add(bg_dim, dim_value)
				fg_dim = color_add(fg_dim, -dim_value)
			end
			local bg_dim_hex = string.format("#%06x", bit.band(bg_dim, 0xffffff))
			local fg_dim_hex = string.format("#%06x", bit.band(fg_dim, 0xffffff))
			local bg_hex = string.format("#%06x", bg)
			local fg_hex = string.format("#%06x", fg)

			local bf = {
				normal = { bg = bg_hex, fg = fg_hex },
				dim = { bg = bg_dim_hex, fg = fg_dim_hex },
			}
			return bf
		end

		print("error: cannot get normal color group")
		return {
			normal = { bg = "#000000", fg = "#ffffff" },
			dim = { bg = "#101010", fg = "#e0e0e0" },
		}
	end

	local setColorSchemeBorder = function()
		local bg_fg = get_bg_fg_color_hex()
		vim.api.nvim_set_hl(0, "ActiveBorderColor", bg_fg.dim)
		vim.api.nvim_set_hl(0, "ActiveCLNColor", bg_fg.dim)
		vim.api.nvim_set_hl(0, "InactiveBorderColor", bg_fg.normal)
		-- Use an autocommand to change the active window's highlights dynamically
		local group = vim.api.nvim_create_augroup("MyColorConfig", { clear = true })
		vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
			group = group,
			callback = function()
				-- When entering a window, set its LineNr to the bright 'ActiveLineNr' color
				vim.wo.winhighlight = table.concat({
					"SignColumn:ActiveBorderColor",
					"LineNr:ActiveBorderColor",
				}, ",")
			end,
		})
		vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
			group = group,
			callback = function()
				-- When leaving a window, set its LineNr back to the dim 'InactiveLineNr' color
				vim.wo.winhighlight = table.concat({
					"SignColumn:InactiveBorderColor",
					"LineNr:InactiveBorderColor",
				}, ",")
			end,
		})
	end
	local au_group = vim.api.nvim_create_augroup("NotifyColorSchemeGroup", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		group = au_group,
		callback = function()
			setColorSchemeBorder()
		end,
	})
	setColorSchemeBorder()
	is_setup = true
end

return M
