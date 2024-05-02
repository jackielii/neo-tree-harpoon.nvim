--This file should have all functions that are in the public api and either set
--or read the state of this source.

local vim = vim
local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local events = require("neo-tree.events")
local utils = require("neo-tree.utils")

local M = {
	-- This is the name our source will be referred to as
	-- within Neo-tree
	name = "harpoon-buffers",
	-- This is how our source will be displayed in the Source Selector
	display_name = " Harpoon Buffers ",
}

local function indexOf(t, value)
	for i, v in ipairs(t) do
		if v == value then
			return i
		end
	end
	return -1
end

local fnmod = vim.fn.fnamemodify

---Navigate to the given path.
---@param path string Path to navigate to. If empty, will navigate to the cwd.
M.navigate = function(state, path, path_to_reveal, callback, async)
	if path == nil then
		path = vim.fn.getcwd()
	end
	state.path = path

	local harpoon = require("harpoon")
	local list = harpoon:list().items

	local items = {}

	for i = 1, #list do
		local item = list[i]
		local path = vim.fn.fnamemodify(item.value, ":p")
		if path then
			table.insert(items, {
				id = path,
				name = vim.fn.fnamemodify(path, ":t"),
				type = "file",
				ext = path:match("%.([-_,()%s%w%i]+)$"),
				path = path,
				extra = {
					index = i,
				},
			})
		end
	end

	local shortenPath = function(parent, fn)
		local tail = fnmod(parent, ":t")
		if tail == "" then
			return fn
		end
		return string.sub(tail, 1, 1) .. "/" .. fn
	end

	-- fix duplicate names to include parent names
	local seen = {}
	for i, item in ipairs(items) do
		if seen[item.name] then
			local index = seen[item.name]
			local path1, path2 = fnmod(items[index].path, ":h"), fnmod(item.path, ":h")
			local name1, name2 = items[index].name, item.name
			while name1 == name2 and path1 ~= path2 do
				name1, name2 = shortenPath(path1, name1), shortenPath(path2, name2)
				path1, path2 = fnmod(path1, ":h"), fnmod(path2, ":h")
			end
			items[index].name = name1
			item.name = name2
		else
			seen[item.name] = i
		end
	end

	renderer.show_nodes(items, state)
end

M.follow = function(callback, force_show)
	if utils.is_floating() then
		return false
	end
	utils.debounce("harpoon-buffers-follow", function()
		local state = manager.get_state(M.name)
		local path_to_reveal = vim.fn.expand("%:p")
		return renderer.focus_node(state, path_to_reveal, true)
	end, 100, utils.debounce_strategy.CALL_LAST_ONLY)
end

---Configures the plugin, should be called before the plugin is used.
---@param config table Configuration table containing any keys that the user
--wants to change from the defaults. May be empty to accept default values.
M.setup = function(config, global_config)
	local Extensions = require("harpoon.extensions")
	local function refresh()
		manager.refresh(M.name)
	end
	Extensions.extensions:add_listener({
		SELECT = M.follow,
		ADD = refresh,
		REMOVE = refresh,
		REORDER = refresh,
		LIST_CHANGE = refresh,
		POSITION_UPDATED = refresh,
	})

	manager.subscribe(M.name, {
		event = events.VIM_BUFFER_ENTER,
		handler = function(args)
			if utils.is_real_file(args.afile) then
				M.follow()
			end
		end,
	})
end

return M
