"""Live updates over WebSocket.

Each app connects to /ws?token=... and is told whenever one of its
accounts changes, so the passbook and balance refresh instantly.
"""
from fastapi import WebSocket

# Police dashboards watch this special key and hear about every change.
ALL = "*"


class ConnectionManager:
    def __init__(self) -> None:
        # account number -> open sockets watching that account
        self._watchers: dict[str, set[WebSocket]] = {}

    def watch(self, ws: WebSocket, account_nos: list[str]) -> None:
        for no in account_nos:
            self._watchers.setdefault(no, set()).add(ws)

    def forget(self, ws: WebSocket) -> None:
        for sockets in self._watchers.values():
            sockets.discard(ws)

    async def account_changed(self, *account_nos: str | None) -> None:
        for no in filter(None, account_nos):
            for ws in list(self._watchers.get(no, ())) + list(self._watchers.get(ALL, ())):
                try:
                    await ws.send_json({"type": "account_changed", "account_no": no})
                except Exception:
                    self.forget(ws)


manager = ConnectionManager()
