local fetchCommandOutput = require('grug-far/engine/fetchCommandOutput')
local getArgs = require('grug-far/engine/astgrep/getArgs')
local parseResults = require('grug-far/engine/astgrep/parseResults')
local utils = require('grug-far/utils')

--- decodes streamed json matches, appending to given table
---@param matches AstgrepMatch[]
---@param data string
local function json_decode_matches(matches, data)
  local json_lines = vim.split(data, '\n')
  for _, json_line in ipairs(json_lines) do
    if #json_line > 0 then
      local match = vim.json.decode(json_line)
      table.insert(matches, match)
    end
  end
end

--- splits off matches corresponding to the last file
---@param matches AstgrepMatch[]
---@return AstgrepMatch[] before, AstgrepMatch[] after
local function split_last_file_matches(matches)
  local end_index = 0
  for i = #matches - 1, 1, -1 do
    if matches[i].file ~= matches[i + 1].file then
      end_index = i
      break
    end
  end

  local before = {}
  for i = 1, end_index do
    table.insert(before, matches[i])
  end
  local after = {}
  for i = end_index + 1, #matches do
    table.insert(after, matches[i])
  end

  return before, after
end

local function getSearchArgs(inputs, options)
  local extraArgs = {
    '--json=stream',
  }
  return getArgs(inputs, options, extraArgs)
end

local function isSearchWithReplacement(args)
  if not args then
    return false
  end

  for i = 1, #args do
    if vim.startswith(args[i], '--rewrite=') or args[i] == '--rewrite' or args[i] == '-r' then
      return true
    end
  end

  return false
end

---@type GrugFarEngine
local AstgrepEngine = {
  type = 'astgrep',

  isSearchWithReplacement = function(inputs, options)
    local args = getSearchArgs(inputs, options)
    return isSearchWithReplacement(args)
  end,

  search = function(params)
    local args = getSearchArgs(params.inputs, params.options)

    local hadOutput = false
    local matches = {}
    return fetchCommandOutput({
      cmd_path = params.options.engines.astgrep.path,
      args = args,
      options = params.options,
      on_fetch_chunk = function(data)
        hadOutput = true
        json_decode_matches(matches, data)
        -- note: we split off last file matches to ensure all matches for a file are processed
        -- at once. This helps with applying replacements
        local before, after = split_last_file_matches(matches)
        matches = after
        params.on_fetch_chunk(parseResults(before))
      end,
      on_finish = function(status, errorMessage)
        if #matches > 0 then
          -- do the last few
          params.on_fetch_chunk(parseResults(matches))
          matches = {}
        end

        -- give the user more feedback when there are no matches
        if status == 'success' and not (errorMessage and #errorMessage > 0) and not hadOutput then
          status = 'error'
          errorMessage = 'no matches'
        end
        params.on_finish(status, errorMessage)
      end,
    })
  end,

  replace = function(params)
    -- TODO (sbadragan): implement if  possible
    -- TODO (sbadragan): blacklist any flags needed
  end,

  isSyncSupported = function()
    return false
  end,

  sync = function()
    -- not supported
  end,

  getInputPrefillsForVisualSelection = function(initialPrefills)
    local prefills = vim.deepcopy(initialPrefills)
    prefills.search = utils.getVisualSelectionText()
    return prefills
  end,
}

return AstgrepEngine