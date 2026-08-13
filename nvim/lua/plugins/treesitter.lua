return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- 1. Install parsers (Replaces `ensure_installed`)
      ts.install({
        "c", "lua", "vim", "vimdoc", "query", "markdown",
        "markdown_inline", "go", "python", "ocaml", "json",
        "yaml", "sql", "terraform", "hcl", "templ"
      }, { summary = false })

      -- 2. Enable native highlighting (Replaces `highlight = { enable = true }`)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
        pattern = "*",
        callback = function(event)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(event.buf))
          if ok and stats and stats.size > max_filesize then
            return
          end

          -- Start treesitter highlighting natively
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
}
