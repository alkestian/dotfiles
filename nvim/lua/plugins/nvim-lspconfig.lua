return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "folke/lazydev.nvim", ft = "lua", opts = {} },
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("templ", {
                filetypes = { "templ" },
                cmd = { "templ", "lsp" },
                capabilities = capabilities,
            })

            vim.lsp.config("terraformls", {
                filetypes = { "terraform", "tf" },
                cmd = { "terraform-ls", "serve" },
                capabilities = capabilities,
            })

            vim.lsp.config("tailwindcss", {
                filetypes = { "html", "css", "scss", "javascript", "typescript", "vue", "svelte", "templ", "gohtml" },
                capabilities = capabilities,
            })

            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            local servers = { "lua_ls", "gopls", "pylsp", "templ", "terraformls", "tailwindcss" }
            for _, server in ipairs(servers) do
                vim.lsp.enable(server)
            end
        end,
    },
}
