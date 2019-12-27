-- operations using 5.2 features

-- Alert: I did not tested this yet!

return {
   -- bit operations
   band   = bit32.band,
   bor    = bit32.bor,
   bxor   = bit32.bxor,
   rshift = bit32.rshift,
   lshift = bit32.lshift,
   bnot   = bit32.bnot,
   unpack = table.unpack
}
