# serial_client.py
import time
import threading
import queue
from typing import Callable, Iterable, Optional

try:
    import serial
    from serial.tools import list_ports
except ImportError as e:
    raise SystemExit("Falta pyserial. Instala con:\n\n    python -m pip install pyserial\n") from e

BAUDRATE = 115200
AUTO_START_ON_CONNECT = True   # Enviar "start" al conectar
SCAN_INTERVAL_SEC = 1.0
RX_TIMEOUT = 0.05

PREFERRED_VID_PIDS = {
    (0x2341, 0x0043),  # Arduino/Genuino Uno
    (0x2A03, 0x0043),  # Arduino SRL Uno
    (0x1A86, 0x7523),  # CH340
    (0x10C4, 0xEA60),  # CP210x
    (0x0403, 0x6001),  # FT232
    (0x2E8A, 0x0005),  # RP2040 CDC
}
PREFERRED_KEYWORDS = ("arduino", "ch340", "cp210", "ftdi", "usb-serial", "cdc")


class SerialAutoClient:
    def __init__(
        self,
        on_rx_line: Callable[[str], None],
        on_status: Optional[Callable[[str], None]] = None,
        baudrate: int = BAUDRATE,
        auto_start_on_connect: bool = AUTO_START_ON_CONNECT,
        preferred_vid_pids: Iterable[tuple[int, int]] = PREFERRED_VID_PIDS,
        preferred_keywords: Iterable[str] = PREFERRED_KEYWORDS,
    ):
        self.on_rx_line = on_rx_line
        self.on_status = on_status or (lambda s: None)
        self.baudrate = baudrate
        self.auto_start_on_connect = auto_start_on_connect
        self.preferred_vid_pids = set(preferred_vid_pids)
        self.preferred_keywords = tuple(k.lower() for k in preferred_keywords)

        self._ser: Optional[serial.Serial] = None
        self._rx_thread: Optional[threading.Thread] = None
        self._mon_thread: Optional[threading.Thread] = None
        self._running = False
        self._partial = b""
        self._last_port: Optional[str] = None
        self._evt_force_rescan = threading.Event()

        self.rx_queue = queue.Queue()

    def start(self) -> None:
        if self._running:
            return
        self._running = True
        self._mon_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self._mon_thread.start()
        self._emit_status("Buscando dispositivo...")

    def stop(self) -> None:
        self._running = False
        self._evt_force_rescan.set()
        self._close_serial()

    def is_connected(self) -> bool:
        return self._ser is not None and self._ser.is_open

    def connected_port(self) -> Optional[str]:
        return self._ser.port if self.is_connected() else None

    def force_rescan(self) -> None:
        self._close_serial()
        self._evt_force_rescan.set()
        self._emit_status("Reescaneando puertos...")

    def send_line(self, line: str) -> None:
        if not self.is_connected():
            raise RuntimeError("No hay puerto serial conectado.")
        if not line.endswith("\n"):
            line += "\n"
        self._ser.write(line.encode("ascii"))

    def _emit_status(self, text: str) -> None:
        try:
            self.on_status(text)
        except Exception:
            pass

    def _monitor_loop(self):
        while self._running:
            if not self.is_connected():
                port = self._choose_port()
                if port:
                    try:
                        self._open_serial(port)
                        self._emit_status(f"Conectado a {port} @ {self.baudrate} baud")
                        if self.auto_start_on_connect:
                            time.sleep(0.25)
                            try:
                                self.send_line("start")
                                self._emit_status(f"Conectado a {port} (start enviado)")
                            except Exception:
                                pass
                    except Exception as e:
                        self._emit_status(f"No se pudo abrir {port}: {e}")
                        self._close_serial()
                else:
                    self._emit_status("Buscando dispositivo...")
                self._evt_force_rescan.wait(SCAN_INTERVAL_SEC)
                self._evt_force_rescan.clear()
            else:
                time.sleep(0.2)

    def _open_serial(self, port: str):
        self._ser = serial.Serial(
            port=port,
            baudrate=self.baudrate,
            timeout=RX_TIMEOUT,
            write_timeout=0.5,
        )
        self._last_port = port
        self._rx_thread = threading.Thread(target=self._rx_loop, daemon=True)
        self._rx_thread.start()

    def _close_serial(self):
        if self._ser:
            try:
                self._ser.close()
            except Exception:
                pass
        self._ser = None
        self._partial = b""
        self._emit_status("Desconectado")

    def _rx_loop(self):
        while self._running and self.is_connected():
            try:
                data = self._ser.read(256)
                if not data:
                    continue
                self._partial += data
                while b"\n" in self._partial:
                    line, self._partial = self._partial.split(b"\n", 1)
                    try:
                        text = line.decode("utf-8", errors="replace")
                    except Exception:
                        text = str(line)
                    self.on_rx_line(text)
                    self.rx_queue.put(text)
            except Exception as e:
                self._emit_status(f"Error de lectura: {e}. Reconectando...")
                self._close_serial()
                break

    def _choose_port(self) -> Optional[str]:
        try:
            ports = list(list_ports.comports())
        except Exception:
            ports = []

        if self._last_port and any(p.device == self._last_port for p in ports):
            return self._last_port

        candidates = []
        for p in ports:
            vid = getattr(p, "vid", None)
            pid = getattr(p, "pid", None)
            if vid is not None and pid is not None and (vid, pid) in self.preferred_vid_pids:
                candidates.append(p.device)

        if not candidates:
            for p in ports:
                desc = f"{p.description or ''} {p.manufacturer or ''}".lower()
                if any(k in desc for k in self.preferred_keywords):
                    candidates.append(p.device)

        if not candidates and ports:
            candidates.append(ports[0].device)

        return candidates[0] if candidates else None
