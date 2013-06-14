
#include <lauxlib.h>

#if !defined(lua_pushliteral)
#define lua_pushliteral(L, s) lua_pushstring(L, "" s, (sizeof(s)/sizeof(char))-1)
#endif

#if !defined(LUA_VERSION_NUM)
#define lua_pushinteger(L, n) lua_pushnumber(L, (lua_Number)n)
#endif

#if !defined LUA_VERSION_NUM
/* Lua 5.0 */
#define luaL_Reg luaL_reg
#endif

#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup);
/* lua_rawlen: Not entirely correct, but should work anyway */
#define lua_rawlen lua_objlen
#define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif
