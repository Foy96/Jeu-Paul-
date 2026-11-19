"""Exécute le gamemode hors de Garry's Mod, dans une simulation de son API.

    pip install lupa
    python3 tests/run.py            # serveur puis client
"""
import sys, glob, os, sqlite3
from lupa import luajit21 as lupa

HERE = os.path.dirname(os.path.abspath(__file__))
GM_DIR = os.path.join(os.path.dirname(HERE), "gamemodes", "shinkairp")

def run(realm, test):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    db = sqlite3.connect(":memory:")
    db.row_factory = sqlite3.Row
    state = {"err": ""}

    def pyfind(pattern):
        assert pattern.startswith("shinkairp/gamemode/"), pattern
        full = os.path.join(GM_DIR, "gamemode", pattern[len("shinkairp/gamemode/"):])
        names = sorted(os.path.basename(p) for p in glob.glob(full))
        return lua.table(*names)

    def pysql(q):
        try:
            cur = db.execute(q)
            rows = cur.fetchall()
            db.commit()
        except Exception as e:
            state["err"] = str(e)
            return False
        if not rows:
            return None
        out = []
        for r in rows:
            out.append(lua.table_from({k: (None if r[k] is None else str(r[k])) for k in r.keys()}))
        return lua.table(*out)

    g.REALM = realm
    g.GAMEMODE_DIR = GM_DIR
    g._pyfind = pyfind
    g._pysql = pysql
    g._pysqlerr = lambda: state["err"]
    lua.execute(open(os.path.join(HERE, "mock.lua"), encoding="utf-8").read())
    if realm == "client":
        lua.execute(open(os.path.join(HERE, "mock_client.lua"), encoding="utf-8").read())
    lua.execute(open(os.path.join(HERE, test), encoding="utf-8").read())

if __name__ == "__main__":
    if len(sys.argv) == 3:
        run(sys.argv[1], sys.argv[2])
    else:
        run("server", "test_server.lua")
        run("client", "test_client.lua")
