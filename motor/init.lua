local PATH = (...):gsub('%.init$', '')
return require (PATH .. "motor")
