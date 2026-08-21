return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        config = function()
            require("persistence").setup()

            local group = vim.api.nvim_create_augroup("persistence_nvimtree", { clear = true })

            -- `mksession` records the nvim-tree window as `file NvimTree_1`, which comes
            -- back as an ordinary listed buffer on restore. Close the tree before saving.
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "PersistenceSavePre",
                callback = function()
                    pcall(vim.cmd, "NvimTreeClose")
                end,
            })

            -- Sessions saved before the hook above still carry the phantom buffer. It
            -- comes back either under its original name or resolved to the cwd, so drop
            -- both: any NvimTree placeholder and any listed directory buffer.
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "PersistenceLoadPost",
                callback = function()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "NvimTree" then
                            local name = vim.api.nvim_buf_get_name(buf)
                            local is_dir = name ~= "" and vim.fn.isdirectory(name) == 1
                            local is_tree = vim.fs.basename(name):match("^NvimTree_%d+$") ~= nil
                            if is_dir or is_tree then
                                pcall(vim.api.nvim_buf_delete, buf, { force = true })
                            end
                        end
                    end
                end,
            })
        end,
    },
}
