return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
     config = function()
      vim.lsp.config('lua_ls', {})
      vim.lsp.enable('lua_ls')

      vim.lsp.config('gopls', {})
      vim.lsp.enable('gopls')

      vim.lsp.config('pylsp', {})
      vim.lsp.enable('pylsp')

      vim.lsp.config('templ', {
        filetypes = { "templ" },
        cmd = { "templ", "lsp" },
      })
      vim.lsp.enable('templ')

      vim.lsp.config('terraformls', {
        filetypes = { "terraform", "tf" },
        cmd = { "terraform-ls", "serve" },
      })
      vim.lsp.enable('terraformls')

      vim.lsp.config('tailwindcss', {
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "templ",
          "gohtml",
        },
      })
      vim.lsp.enable('tailwindcss')
      vim.lsp.config('rust_analyzer', {})
      vim.lsp.enable('rust_analyzer')
      vim.lsp.config('buf_ls', {
        cmd = { "buf", "lsp", "serve" },
        filetypes = { "proto" },
        root_dir = require("lspconfig.util").root_pattern("buf.yaml", "buf.work.yaml", ".git"),
        single_file_support = true,
      })
      vim.lsp.enable('buf_ls')

      -- vim.lsp.config('sqlls', {
      --   cmd = { "sql-language-server", "up", "--method", "stdio" },
      --   filetypes = { "sql", "mysql" },
      --   root_dir = function()
      --     return vim.loop.cwd()
      --   end,
      -- })
      -- vim.lsp.enable('sqlls')

      require("cmp_nvim_lsp").default_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end
        end,
      })
    end,  
  },
}
