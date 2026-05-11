-- Thin MCP JSON-RPC client over the StudioMCP proxy's WebSocket endpoint.
--
-- The StudioMCP binary (already running if the user has Studio MCP set up for
-- Claude/Cursor/etc.) exposes:
--   ws://127.0.0.1:13469/studio  ← where the Assistant plugin connects
--   ws://127.0.0.1:13469/proxy   ← where external MCP clients connect
--   http://127.0.0.1:13469/health
--
-- We connect as a proxy client. The proxy multiplexes us with the Assistant
-- plugin, which is what actually executes tools like start_stop_play using
-- privileged APIs a third-party plugin can't touch.

local HttpService = game:GetService("HttpService")

local M = {}

local PROXY_URL = "ws://127.0.0.1:13469/proxy"
local PROTOCOL_VERSION = "2024-11-05"
local CLIENT_INFO = { name = "tutorial-generator", version = "0.1.0" }

-- One-shot call: open a WS, run the MCP handshake, invoke a single tool, close.
-- Returns (ok, resultOrErr). Blocks the calling thread (meant to run inside
-- task.spawn so the UI thread stays responsive).
function M.callTool(toolName: string, arguments: { [string]: any }, timeoutSec: number?): (boolean, any)
	local timeout = timeoutSec or 5

	local okCreate, client = pcall(function()
		return HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, {
			Url = PROXY_URL,
			Method = "GET",
		})
	end)
	if not okCreate then
		return false, `CreateWebStreamClient failed: {client}`
	end

	local nextId = 0
	local function newId(): number
		nextId += 1
		return nextId
	end

	local pending: { [number]: thread } = {}
	local results: { [number]: any } = {}
	local fatalErr: string? = nil
	local mainThread = coroutine.running()
	local opened = false

	local function finish(err: string?)
		if fatalErr then return end
		fatalErr = err
		-- Wake any pending waiters.
		for id, co in pairs(pending) do
			pending[id] = nil
			task.spawn(co, nil)
		end
		if not opened then
			task.spawn(mainThread)
		end
	end

	client.Opened:Connect(function()
		opened = true
		task.spawn(mainThread)
	end)
	client.Error:Connect(function(_status, msg)
		finish(`ws error: {msg}`)
	end)
	client.Closed:Connect(function()
		finish("ws closed")
	end)

	client.MessageReceived:Connect(function(message)
		local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, message)
		if not okDecode then return end
		local id = decoded.id
		if id and pending[id] then
			results[id] = decoded
			local co = pending[id]
			pending[id] = nil
			task.spawn(co)
		end
	end)

	-- Wait for Opened (or timeout / error).
	local openTimer = task.delay(timeout, function()
		if not opened then finish("connect timeout") end
	end)
	coroutine.yield()
	pcall(task.cancel, openTimer)
	if fatalErr then
		pcall(function() client:Close() end)
		return false, fatalErr
	end

	local function request(method: string, params: any?): (boolean, any)
		local id = newId()
		local payload = HttpService:JSONEncode({
			jsonrpc = "2.0",
			id = id,
			method = method,
			params = params,
		})
		local caller = coroutine.running()
		pending[id] = caller
		local okSend, sendErr = pcall(function() client:Send(payload) end)
		if not okSend then
			pending[id] = nil
			return false, `send failed: {sendErr}`
		end
		local timer = task.delay(timeout, function()
			if pending[id] then
				pending[id] = nil
				task.spawn(caller)
			end
		end)
		coroutine.yield()
		pcall(task.cancel, timer)
		local resp = results[id]
		results[id] = nil
		if fatalErr then return false, fatalErr end
		if not resp then return false, `{method} timed out` end
		if resp.error then
			return false, (resp.error and resp.error.message) or "rpc error"
		end
		return true, resp.result
	end

	local function notify(method: string, params: any?)
		local payload = HttpService:JSONEncode({
			jsonrpc = "2.0",
			method = method,
			params = params,
		})
		pcall(function() client:Send(payload) end)
	end

	-- MCP handshake.
	local okInit, initErr = request("initialize", {
		protocolVersion = PROTOCOL_VERSION,
		capabilities = {},
		clientInfo = CLIENT_INFO,
	})
	if not okInit then
		pcall(function() client:Close() end)
		return false, initErr
	end
	notify("notifications/initialized", nil)

	local okCall, callResult = request("tools/call", {
		name = toolName,
		arguments = arguments,
	})
	pcall(function() client:Close() end)
	return okCall, callResult
end

return M
