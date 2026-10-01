return {
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        hijack_directories = {
          enable = true,
          auto_open = false,
        },
        update_focused_file = {
          enable = true,
          update_root = false,
        },
        view = {
          width = {
            min = 30,
            max = 90,
            padding = 1,
          },
        },
      })
    end
  }
}
