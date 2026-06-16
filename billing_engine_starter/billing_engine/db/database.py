"""
Database connection helper.

✅ COMPLETE. Use this from repositories; do not call sqlite3 directly elsewhere.

Usage:
    db = Database("billing.db")
    db.init_schema()                 # one-time setup
    with db.transaction() as conn:   # for multi-statement atomic work
        conn.execute("INSERT ...")
        conn.execute("INSERT ...")
"""
import sqlite3
from contextlib import contextmanager

class Database:
    def __init__(self, path):
        self.path = path

    def init_schema(self):
        with self.transaction() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS customers (
                    id INTEGER PRIMARY KEY,
                    name TEXT
                );
            """)

    @contextmanager
    def transaction(self):
        conn = sqlite3.connect(self.path)
        try:
            yield conn
            conn.commit()
        except:
            conn.rollback()
            raise
        finally:
            conn.close()


