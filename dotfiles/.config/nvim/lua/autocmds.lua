require "nvchad.autocmds"
-- Reload NvChad colors when matugen/chadwal updates base46 file
vim.o.autoread = true

vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
  pattern = "base46-dark.lua",
  callback = function()
    vim.schedule(function()
      package.loaded["base46"] = nil
      require("base46").load_all_highlights()
      vim.notify("🎨 base46 reloaded from matugen", vim.log.levels.INFO)
    end)
  end,
})

