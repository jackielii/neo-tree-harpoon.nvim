--This file should contain all commands meant to be used by mappings.
local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local vim = vim

local M = {}

-- M.example_command = function(state)
-- 	local tree = state.tree
-- 	local node = tree:get_node()
-- 	local id = node:get_id()
-- 	local name = node.name
-- 	print(string.format("example_command: id=%s, name=%s", id, name))
-- end

local function get_rel_path(path)
	local Path = require("plenary.path")
	return Path:new(path):make_relative(vim.loop.cwd())
end

M.refresh = function(state)
	manager.refresh("harpoon-buffers", state)
end

M.show_debug_info = function(state)
	print(vim.inspect(state))
end

M.delete = function(state)
	local node = state.tree:get_node()
	if node then
		if node.type == "message" then
			return
		end
		local list = require("harpoon"):list()
		local item = list:get_by_value(get_rel_path(node.path))
		if item then
			list:remove(item)
		end
		M.refresh(state)
	end
end

cc._add_common_commands(M)
return M
