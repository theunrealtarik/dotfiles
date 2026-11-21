hl.layer_rule({
    name = "blur_powermenu",
    match = { namespace = "gtk-layer-shell" },
    blur = true,
    ignore_alpha = 0.1,
    xray = true,
})
