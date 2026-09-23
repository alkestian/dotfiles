return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      spec = (function()
        local spec = {}
        for i = 1, 9 do
          table.insert(spec, { "<leader>t" .. i, desc = i == 1 and "1..9: Go to Buffer N" or nil, hidden = i ~= 1 })
          table.insert(spec, { "<leader>tc" .. i, desc = i == 1 and "1..9: Close Buffer N" or nil, hidden = i ~= 1 })
        end
        return spec
      end)(),
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
      {
        "<leader>K",
        function()
          require("which-key").show({ global = true })
        end,
        desc = "All Keymaps (which-key)",
      },
    },
  },
}
