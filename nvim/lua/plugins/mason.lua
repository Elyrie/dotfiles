return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "mypy",
        "flake8",
        "black",
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    config = function() end,
  },
}
