return {
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        update_focused_file = {
          enable = true,
          update_root = false,
        },
        view = {
          adaptive_size = true,
          min_width = 30,
          max_width = 90,
        },
      })
    end
  }
}
