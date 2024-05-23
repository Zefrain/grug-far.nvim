local MiniTest = require('mini.test')
local helpers = require('grug-far/test/helpers')
local screenshot = require('grug-far/test/screenshot')
local expect = MiniTest.expect

---@type NeovimChild
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      helpers.initChildNeovim(child)
    end,
    -- Stop once all test cases are finished
    post_once = child.stop,
  },
})

T['can search for some string'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

T['can search for some string with many matches'] = function()
  local files = {}
  for i = 1, 100 do
    table.insert(files, {
      filename = 'file_' .. i,
      content = [[
        grug walks many steps
        grug talks and grug drinks
        then grug thinks
      ]],
    })
  end
  helpers.writeTestFiles(files)

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

T['can search with flags'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = '--ignore-case' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

T['can search with particular file in flags'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = './file1 --ignore-case' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

T['can search with file filter'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug', filesFilter = '**/*.txt' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

T['can search with replace string'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug', replacement = 'curly' },
  })

  helpers.childWaitForFinishedStatus(child)

  expect.reference_screenshot(child.get_screenshot())
  expect.reference_screenshot(screenshot.fromChildBufLines(child))
end

return T