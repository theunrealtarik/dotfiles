local monitors = {
    { name = "DP-1", first = 1, last = 4 },
    { name = "DP-3", first = 5, last = 8 },
}

for _, monitor in ipairs(monitors) do
    for workspace = monitor.first, monitor.last do
        hl.workspace_rule({
            workspace = tostring(workspace),
            monitor = monitor.name,
            default = workspace == monitor.first,
            persistent = true,
        })
    end
end

hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

package.path = package.path .. ";./?.lua;./?/init.lua"
local ok, smw = pcall(require, "plugins.split-monitor-workspaces")
if ok then
    smw.setup({
        workspace_count = 4,
        monitor_priority = { "DP-1", "DP-3" },
        max_workspaces = { ["DP-1"] = 4, ["DP-3"] = 4 },
        keep_focused = false,
        enable_notifications = false,
        enable_persistent_workspaces = true,
        link_monitors = true,
    })
else
    hl.notification.create({
        text = "split-monitor-workspaces Lua package unavailable; using fixed workspace mapping",
        timeout = 8000,
        icon = "warning",
    })
end
