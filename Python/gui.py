# teclado_gui.py
import time
import tkinter as tk
from tkinter import ttk, messagebox

from serial_client import SerialAutoClient  # mismo folder


# ===== Paleta Dark Souls 3 (aprox) =====
COL_BG       = "#1b1a18"  # fondo principal (negro con tinte sepia)
COL_PANEL    = "#211f1c"  # paneles
COL_TEXT     = "#e2d9b5"  # texto pergamino
COL_TEXT_DIM = "#cbbf93"
COL_GOLD     = "#c9a55b"  # dorado principal
COL_GOLD_DK  = "#a7863b"  # dorado oscuro (bordes)
COL_BTN      = "#2a2825"  # botón
COL_BTN_HOV  = "#3a382f"  # hover
COL_ENTRY    = "#12110f"  # fondo input
COL_ENTRY_FG = "#f0e7c7"


def apply_ds3_theme(root: tk.Tk):
    """Configura estilos ttk para look & feel tipo Dark Souls 3."""
    style = ttk.Style(root)
    # Forzar un tema que respete colores
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass

    # Colores base de widgets
    root.configure(bg=COL_BG)
    style.configure(".", background=COL_BG, foreground=COL_TEXT)

    # Frames / Labelframes
    style.configure("DS3.TFrame", background=COL_BG)
    style.configure(
        "DS3.TLabelframe",
        background=COL_PANEL,
        foreground=COL_TEXT,
        bordercolor=COL_GOLD_DK,
        relief="flat",
        borderwidth=1
    )
    style.configure(
        "DS3.TLabelframe.Label",
        background=COL_PANEL,
        foreground=COL_GOLD,
        font=("Georgia", 11, "bold")
    )

    # Labels
    style.configure(
        "DS3.TLabel",
        background=COL_BG,
        foreground=COL_TEXT,
        font=("Georgia", 10)
    )
    style.configure(
        "DS3.Subtle.TLabel",
        background=COL_BG,
        foreground=COL_TEXT_DIM,
        font=("Georgia", 10, "italic")
    )
    style.configure(
        "DS3.Title.TLabel",
        background=COL_BG,
        foreground=COL_GOLD,
        font=("Georgia", 16, "bold")
    )

    # Botones
    style.configure(
        "DS3.TButton",
        background=COL_BTN,
        foreground=COL_TEXT,
        bordercolor=COL_GOLD_DK,
        focusthickness=1,
        focuscolor=COL_GOLD_DK,
        relief="flat",
        padding=(12, 6)
    )
    style.map(
        "DS3.TButton",
        background=[("active", COL_BTN_HOV)],
        foreground=[("disabled", "#7f7759")],
        relief=[("pressed", "flat")]
    )

    # Entry
    style.configure(
        "DS3.TEntry",
        fieldbackground=COL_ENTRY,
        background=COL_ENTRY,
        foreground=COL_ENTRY_FG,
        bordercolor=COL_GOLD_DK,
        lightcolor=COL_GOLD_DK,
        darkcolor=COL_GOLD_DK,
        padding=6
    )

    # Checkbutton / Radiobutton (por si los usas luego)
    style.configure(
        "DS3.TCheckbutton",
        background=COL_BG, foreground=COL_TEXT
    )
    style.configure(
        "DS3.TRadiobutton",
        background=COL_BG, foreground=COL_TEXT
    )

    # Separador dorado
    style.configure("DS3.TSeparator", background=COL_GOLD_DK)


def golden_frame(parent, padding=(10, 8)):
    """
    Crea un marco con borde dorado estilo DS3: un Frame oscuro con
    un borde 1px dorado y relleno interno.
    """
    outer = tk.Frame(parent, bg=COL_BG, highlightthickness=1,
                     highlightbackground=COL_GOLD_DK, highlightcolor=COL_GOLD_DK)
    inner = tk.Frame(outer, bg=COL_PANEL)
    inner.pack(fill="both", expand=True, padx=padding[0], pady=padding[1])
    return outer, inner


class TecladoGUI:
    def __init__(self, root: tk.Tk):
        apply_ds3_theme(root)
        self.root = root
        self.root.title("Teclado Numérico")
        # Un leve margen alrededor
        container = ttk.Frame(root, style="DS3.TFrame", padding=12)
        container.pack(fill="both", expand=True)

        # ===== Título =====
        title = ttk.Label(container, text="Teclado Numérico", style="DS3.Title.TLabel")
        title.pack(anchor="w", pady=(0, 6))

        subtitle = ttk.Label(
            container,
            text="Envío binario (bytes 8 bits, big-endian) con auto-conexión",
            style="DS3.Subtle.TLabel"
        )
        subtitle.pack(anchor="w", pady=(0, 12))

        # ===== Barra superior: estado + acciones =====
        top_outer, top = golden_frame(container, padding=(10, 8))
        top_outer.pack(fill="x", pady=(0, 10))
        # Estado
        self.status_var = tk.StringVar(value="Inicializando...")
        status_lbl = ttk.Label(top, textvariable=self.status_var, style="DS3.TLabel")
        status_lbl.grid(row=0, column=0, sticky="w")

        # Botones acción
        btns = ttk.Frame(top, style="DS3.TFrame")
        btns.grid(row=0, column=1, sticky="e")
        ttk.Button(btns, text="Start", style="DS3.TButton",
                   command=lambda: self._send_line_safe("start")).pack(side="left", padx=5)
        ttk.Button(btns, text="End", style="DS3.TButton",
                   command=lambda: self._send_line_safe("end")).pack(side="left", padx=5)
        ttk.Button(btns, text="Reintentar", style="DS3.TButton",
                   command=self._force_rescan).pack(side="left", padx=5)

        top.grid_columnconfigure(0, weight=1)

        # ===== Buffer (entrada + enviar) =====
        buf_outer, buf = golden_frame(container, padding=(12, 10))
        buf_outer.pack(fill="x", pady=(0, 10))

        # Etiqueta del buffer
        ttk.Label(
            buf,
            text="Número a enviar",
            style="DS3.TLabel"
        ).grid(row=0, column=0, sticky="w", padx=(0, 6), pady=(0, 4))

        self.buffer_var = tk.StringVar(value="")
        self.entry = ttk.Entry(buf, style="DS3.TEntry", textvariable=self.buffer_var, width=40)
        self.entry.grid(row=1, column=0, padx=(0, 8), pady=4, sticky="we", columnspan=4)
        self.entry.bind("<Return>", lambda e: self._send_buffer())
        self.entry.bind("<KP_Enter>", lambda e: self._send_buffer())

        ttk.Button(buf, text="← Borrar", style="DS3.TButton",
                   command=self._backspace).grid(row=1, column=4, padx=4, pady=4)
        ttk.Button(buf, text="C", style="DS3.TButton",
                   command=self._clear_buffer).grid(row=1, column=5, padx=4, pady=4)

        self.clear_after_var = tk.BooleanVar(value=True)
        # Usamos tk.Checkbutton para poder colorear fondo fácilmente
        clear_chk = tk.Checkbutton(
            buf, text="Limpiar tras enviar",
            variable=self.clear_after_var,
            bg=COL_PANEL, fg=COL_TEXT, activebackground=COL_PANEL,
            selectcolor=COL_BG, highlightthickness=0
        )
        clear_chk.grid(row=1, column=6, padx=6, pady=4)

        ttk.Button(buf, text="Enviar", style="DS3.TButton",
                   command=self._send_buffer).grid(row=1, column=7, padx=8, pady=4)

        for i in range(4):
            buf.grid_columnconfigure(i, weight=1)

        # Separador dorado sutil
        ttk.Separator(container, orient="horizontal", style="DS3.TSeparator").pack(fill="x", pady=6)

        # ===== Teclado numérico =====
        kb_outer, kb = golden_frame(container, padding=(12, 10))
        kb_outer.pack(pady=(0, 10))

        layout = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["",  "0", ""],
        ]
        for r, row in enumerate(layout):
            for c, label in enumerate(row):
                if label:
                    ttk.Button(
                        kb, text=label, style="DS3.TButton", width=6,
                        command=lambda x=label: self._append_digit(x)
                    ).grid(row=r, column=c, padx=8, pady=8)
                else:
                    tk.Label(kb, text=" ", bg=COL_PANEL).grid(row=r, column=c, padx=8, pady=8)

        # Atajos de teclado para 0–9
        for ch in "0123456789":
            root.bind(ch, lambda e, x=ch: self._append_digit(x))

        # ===== Cliente serial (conexión invisible) =====
        self.client = SerialAutoClient(
            on_rx_line=lambda _line: None,   # sin consola
            on_status=self._set_status,
        )
        self.client.start()

        # Cierre ordenado
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

    # ===== Estado =====
    def _set_status(self, text: str):
        self.status_var.set(text)

    # ===== Utilidades de UI =====
    def _append_digit(self, ch: str):
        self.buffer_var.set(self.buffer_var.get() + ch)
        self.entry.icursor("end")
        self.entry.focus_set()

    def _backspace(self):
        s = self.buffer_var.get()
        if s:
            self.buffer_var.set(s[:-1])

    def _clear_buffer(self):
        self.buffer_var.set("")

    def _force_rescan(self):
        self._set_status("Reescaneando puertos…")
        self.client.force_rescan()

    # ===== Envío siempre BINARIO (8b big-endian) =====
    def _send_line_safe(self, line: str):
        if not self.client.is_connected():
            messagebox.showwarning("No conectado", "Aún no se ha detectado el dispositivo. Pulsa 'Reintentar'.")
            return
        try:
            self.client.send_line(line)
        except Exception as e:
            messagebox.showerror("Error al enviar", str(e))

    def _send_buffer(self):
        num_str = self.buffer_var.get().strip()
        if not num_str:
            messagebox.showinfo("Vacío", "No hay dígitos para enviar.")
            return
        if not num_str.isdigit():
            messagebox.showerror("Dato inválido", "Solo se permiten dígitos 0–9.")
            return
        if not self.client.is_connected():
            messagebox.showwarning("No conectado", "Aún no se ha detectado el dispositivo. Pulsa 'Reintentar'.")
            return

        try:
            # Convertir decimal a bytes big-endian (0 => 0x00)
            n = int(num_str)
            out = [0] if n == 0 else []
            while n > 0:
                out.append(n & 0xFF)
                n >>= 8
            out.reverse()  # MSB primero

            for b in out:
                self.client.send_line(f"send;0x{b:02X};8")
                time.sleep(0.01)

            if self.clear_after_var.get():
                self._clear_buffer()

        except Exception as e:
            messagebox.showerror("Error al enviar", str(e))

    # ===== Cierre =====
    def _on_close(self):
        try:
            self.client.stop()
        except Exception:
            pass
        self.root.destroy()


def main():
    root = tk.Tk()
    # Tipografía serif “tipo DS3”; caer a Times si Georgia no está
    try:
        from tkinter import font as tkfont
        base = tkfont.nametofont("TkDefaultFont")
        base.configure(family="Georgia", size=10)
    except Exception:
        pass
    app = TecladoGUI(root)
    root.minsize(600, 420)
    root.mainloop()


if __name__ == "__main__":
    main()
