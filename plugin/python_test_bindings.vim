" Description: python_test_bindings.vim - Some basic functionality for navigating between tests & implementation in a specific python project (assumes pytest is the test runner)
" Author:      Michael Thelander <mjthelander@gmail.com>
" License:     This file is placed in the public domain

if exists('g:loaded_python_vim_test_bindings')
  finish
endif

let g:project_dir = 'linear' " Override this for a different project name
let g:pytest_args = '-ra'

function OpenTest()
  execute ':e ' . GetTestFile()
endfunction

function OpenTestHoriz()
  execute ':sp ' . GetTestFile()
endfunction

function OpenImplementation()
  execute ':e ' . GetImplementation()
endfunction

function OpenImplementationHoriz()
  execute ':sp ' . GetImplementation()
endfunction

function CurrentFilename()
  return expand('%:p')
endfunction

function RootDir()
  return Chomp(system('git rev-parse --show-toplevel')) . '/python'
endfunction

function Chomp(str)
  return substitute(a:str, '\n\+$', '', '')
endfunction

function GetTestFile()
  let filename = CurrentFilename()
  if stridx(filename, '/tests/') < 0
    let l:testfile = substitute(filename, '/' . g:project_dir . '/', '/tests/' . g:project_dir . '/', '')
    let l:testfile = substitute(l:testfile, '/\([^/]*.py\)$', '/test_\1', '')
    return l:testfile
  endif
  return filename
endfunction

function GetImplementation()
  let filename = CurrentFilename()
  if stridx(filename, '/tests/') >= 0
    let l:testfile = substitute(filename, '/tests/', '/', '')
    let l:testfile = substitute(l:testfile, '/test_\(.*.py\)$', '/\1', '')
    return l:testfile
  endif
  return filename
endfunction

function _RunTest(filename)
  let root = RootDir()
  let command = '!(clear && cd ' . root . ' && pipenv run pytest ' . g:pytest_args . ' ' . a:filename . ')'
  execute command
endfunction

function RunTests()
  " TODO: go to test if not in one
  :write!
  :redraw!

  call _RunTest(CurrentFilename())
endfunction

function RunTest()
  :write!
  :redraw!

  let cls = _GetCurrentClassName()
  let l:fn = _GetCurrentTestFunctionName()
  if empty(l:fn)
    echom 'No test function name found!'
  else
    if !empty(cls)
      let l:fn = cls . '::' . l:fn
    endif
    call _RunTest(CurrentFilename() . '::' . l:fn)
  endif
endfunction

function _GetCurrentClassName()
  let view = winsaveview()

  call cursor(line('.') + 1, col(1))
  let class_pattern = '^ *class *.*: *$'
  let result = ''

  if search(class_pattern, 'bW') || search(class_pattern, 'W')
    let result = matchstr(getline('.'), ' *class *\v[^\(]*')
    let result = substitute(result, 'class ', '', '')
  endif

  call winrestview(view)
  return result
endfunction

function _GetCurrentTestFunctionName()
  let view = winsaveview()

  call cursor(line('.') + 1, col(1))
  let test_pattern = '^ *def *test_.*$'
  let result = ''

  if search(test_pattern, 'bW') || search(test_pattern, 'W')
    let result = matchstr(getline('.'), '\zstest_[^\($]*\ze')
  endif

  call winrestview(view)
  return result
endfunction

function OpenBaseClass()
  let view = winsaveview()
  let class_pattern = '\v^ *class *[^(]+\(.+\): *$'
  if search(class_pattern, 'bW') || search(class_pattern, 'W')
    let cls = matchstr(getline('.'), '\v\(\zs.+\ze\)')

    let import_pattern = '\v *from *\zs[^ ]+\ze *import *' . cls
    if search(import_pattern, 'bW')
      let import_line = matchstr(getline('.'), import_pattern)
      let import_line = substitute(import_line, '\v\.', '/', '')
      let root = RootDir()
      execute ':edit ' . root . '/' . import_line . '.py'
    else
      echom 'Could not find an import statement for ' . cls
    endif
  else
    echom 'Could not find a base class'
  endif
  call winrestview(view)
endfunction

function _MakePythonFile(basedir, module)
  let path = substitute(a:module, '\.', '/', 'g')
  let fullpath = a:basedir . '/' . path . '.py'
  return substitute(fullpath, '//', '/', 'g')
endfunction

function OpenModule()
  let current_line = getline('.')
  let root = RootDir()
  if match(current_line, '\v^ *from *[^ ]+ *import') >= 0
    let path = matchstr(current_line, '\v^ *from *\zs[^ ]+\ze *import')
    execute ':edit ' . _MakePythonFile(root, path)
  elseif match(current_line, '\v^ *import *\..+ *') >= 0
    let path = matchstr(current_line, '\v^ *import *\zs\.[^ ]+\ze *$')
    let path = _MakePythonFile(getcwd(), path)
    execute ':edit ' . path
  elseif match(current_line, '\v^ *import *.+ *') >= 0
    let path = matchstr(current_line, '\v^ *import *\zs.+\ze *$')
    let path = _MakePythonFile(root, path)
    execute ':edit ' . path
  else
    echom 'No module found under cursor'
  endif
endfunction

nnoremap ,gt :call OpenTest()<CR>
nnoremap ;gt :call OpenTestHoriz()<CR>

nnoremap ,gi :call OpenImplementation()<CR>
nnoremap ;gi :call OpenImplementationHoriz()<CR>

nnoremap ,T :call RunTests()<CR>
nnoremap ,t :call RunTest()<CR>
nnoremap ,gb :call OpenBaseClass()<CR>
nnoremap ,gm :call OpenModule()<CR>

let g:loaded_python_vim_test_bindings = 1
