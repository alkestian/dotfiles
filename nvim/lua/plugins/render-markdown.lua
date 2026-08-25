return {
  {
    "echasnovski/mini.icons",
    opts = {},
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown" },
    opts = {
      code = {
        style = "full",
        border = "thick",
        left_pad = 2,
        right_pad = 2,
      },
    },
  },
}
