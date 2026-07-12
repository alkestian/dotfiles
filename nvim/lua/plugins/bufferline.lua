return {
    {
        "akinsho/bufferline.nvim",
        enabled = true,
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("bufferline").setup()
        end,
    },
}
