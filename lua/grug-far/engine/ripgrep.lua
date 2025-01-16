local search = require('grug-far.engine.ripgrep.search')
local replace = require('grug-far.engine.ripgrep.replace')
local sync = require('grug-far.engine.ripgrep.sync')

---@type GrugFarEngine
local RipgrepEngine = {
  type = 'ripgrep',

  isSearchWithReplacement = function(inputs, options)
    local args = search.getSearchArgs(inputs, options)
    return search.isSearchWithReplacement(args)
  end,

  showsReplaceDiff = function(options)
    return options.engines.ripgrep.showReplaceDiff
  end,

  search = search.search,

  replace = replace.replace,

  isSyncSupported = function()
    return true
  end,

  sync = sync.sync,

  getInputPrefillsForVisualSelection = function(visual_selection, initialPrefills)
    local prefills = vim.deepcopy(initialPrefills)

    prefills.search = table.concat(visual_selection, '\n')
    local flags = prefills.flags or ''
    if #visual_selection > 1 and not flags:find('%-%-multiline') then
      flags = (#flags > 0 and flags .. ' ' or flags) .. '--multiline'
    else
      prefills.search = '\\b' .. prefills.search .. '\\b'
    end
    prefills.flags = flags

    return prefills
  end,
}

return RipgrepEngine
