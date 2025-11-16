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
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass

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
        borderwidth=1,
    )
    style.configure(
        "DS3.TLabelframe.Label",
        background=COL_PANEL,
        foreground=COL_GOLD,
        font=("Georgia", 11, "bold"),
    )

    # Labels
    style.configure(
        "DS3.TLabel",
        background=COL_BG,
        foreground=COL_TEXT,
        font=("Georgia", 10),
    )
    style.configure(
        "DS3.Subtle.TLabel",
        background=COL_BG,
        foreground=COL_TEXT_DIM,
        font=("Georgia", 10, "italic"),
    )
    style.configure(
        "DS3.Title.TLabel",
        background=COL_BG,
        foreground=COL_GOLD,
        font=("Georgia", 16, "bold"),
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
        padding=(12, 6),
    )
    style.map(
        "DS3.TButton",
        background=[("active", COL_BTN_HOV)],
        foreground=[("disabled", "#7f7759")],
        relief=[("pressed", "flat")],
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
        padding=6,
    )

    # Check / radio
    style.configure("DS3.TCheckbutton", background=COL_BG, foreground=COL_TEXT)
    style.configure("DS3.TRadiobutton", background=COL_BG, foreground=COL_TEXT)

    # Separador dorado
    style.configure("DS3.TSeparator", background=COL_GOLD_DK)


def golden_frame(parent, padding=(10, 8)):
    """Marco con borde dorado estilo DS3."""
    outer = tk.Frame(
        parent,
        bg=COL_BG,
        highlightthickness=1,
        highlightbackground=COL_GOLD_DK,
        highlightcolor=COL_GOLD_DK,
    )
    inner = tk.Frame(outer, bg=COL_PANEL)
    inner.pack(fill="both", expand=True, padx=padding[0], pady=padding[1])
    return outer, inner


class TecladoGUI:
    """
    GUI para enviar expresiones A op B al Arduino.
    El Arduino recibe algo tipo: "3+5\n" y se encarga del SPI.
    """

    def __init__(self, root: tk.Tk):
        apply_ds3_theme(root)
        self.root = root
        self.root.title("Calculadora SPI - Teclado Numérico")

        container = ttk.Frame(root, style="DS3.TFrame", padding=12)
        container.pack(fill="both", expand=True)

        # ===== Título =====
        title = ttk.Label(
            container, text="Calculadora SPI", style="DS3.Title.TLabel"
        )
        title.pack(anchor="w", pady=(0, 6))

        subtitle = ttk.Label(
            container,
            text="Ingresa A y B con el pad numérico y envía A op B al FPGA.",
            style="DS3.Subtle.TLabel",
        )
        subtitle.pack(anchor="w", pady=(0, 12))

        # ===== Barra superior: estado + acciones =====
        top_outer, top = golden_frame(container, padding=(10, 8))
        top_outer.pack(fill="x", pady=(0, 10))

        self.status_var = tk.StringVar(value="Inicializando...")
        status_lbl = ttk.Label(top, textvariable=self.status_var, style="DS3.TLabel")
        status_lbl.grid(row=0, column=0, sticky="w")

        btns = ttk.Frame(top, style="DS3.TFrame")
        btns.grid(row=0, column=1, sticky="e")
        ttk.Button(
            btns,
            text="Start",
            style="DS3.TButton",
            command=lambda: self._send_line_safe("start"),
        ).pack(side="left", padx=5)
        ttk.Button(
            btns,
            text="End",
            style="DS3.TButton",
            command=lambda: self._send_line_safe("end"),
        ).pack(side="left", padx=5)
        ttk.Button(
            btns, text="Reintentar", style="DS3.TButton", command=self._force_rescan
        ).pack(side="left", padx=5)

        top.grid_columnconfigure(0, weight=1)

        # ===== Panel de operandos y operador =====
        ops_outer, ops = golden_frame(container, padding=(12, 10))
        ops_outer.pack(fill="x", pady=(0, 10))

        # Variables para A, B, operador y campo activo
        self.a_var = tk.StringVar(value="")
        self.b_var = tk.StringVar(value="")
        self.op_var = tk.StringVar(value="+")      # + por defecto
        self.active_field = tk.StringVar(value="A")  # A o B

        # Fila 0: campos A y B
        ttk.Label(ops, text="A:", style="DS3.TLabel").grid(
            row=0, column=0, sticky="w", padx=(0, 4), pady=4
        )
        self.entry_a = ttk.Entry(
            ops, style="DS3.TEntry", textvariable=self.a_var, width=8
        )
        self.entry_a.grid(row=0, column=1, padx=(0, 12), pady=4, sticky="w")

        ttk.Label(ops, text="B:", style="DS3.TLabel").grid(
            row=0, column=2, sticky="w", padx=(0, 4), pady=4
        )
        self.entry_b = ttk.Entry(
            ops, style="DS3.TEntry", textvariable=self.b_var, width=8
        )
        self.entry_b.grid(row=0, column=3, padx=(0, 12), pady=4, sticky="w")

        # Fila 1: selección de campo activo (pad numérico escribe ahí)
        ttk.Label(
            ops,
            text="Campo activo:",
            style="DS3.TLabel",
        ).grid(row=1, column=0, sticky="w", pady=(4, 4))

        rb_frame = ttk.Frame(ops, style="DS3.TFrame")
        rb_frame.grid(row=1, column=1, columnspan=3, sticky="w", pady=(4, 4))
        ttk.Radiobutton(
            rb_frame,
            text="A",
            style="DS3.TRadiobutton",
            value="A",
            variable=self.active_field,
            command=self._focus_active_entry,
        ).pack(side="left", padx=4)
        ttk.Radiobutton(
            rb_frame,
            text="B",
            style="DS3.TRadiobutton",
            value="B",
            variable=self.active_field,
            command=self._focus_active_entry,
        ).pack(side="left", padx=4)

        # Fila 2: operador
        ttk.Label(
            ops,
            text="Operador:",
            style="DS3.TLabel",
        ).grid(row=2, column=0, sticky="w", pady=(4, 4))

        op_frame = ttk.Frame(ops, style="DS3.TFrame")
        op_frame.grid(row=2, column=1, columnspan=3, sticky="w", pady=(4, 4))

        for symbol in ["+", "-", "*", "/"]:
            ttk.Radiobutton(
                op_frame,
                text=symbol,
                style="DS3.TRadiobutton",
                value=symbol,
                variable=self.op_var,
            ).pack(side="left", padx=4)

        # Fila 3: botones de edición y enviar
        edit_frame = ttk.Frame(ops, style="DS3.TFrame")
        edit_frame.grid(row=3, column=0, columnspan=4, sticky="w", pady=(8, 0))

        ttk.Button(
            edit_frame, text="← Borrar", style="DS3.TButton", command=self._backspace
        ).pack(side="left", padx=4)
        ttk.Button(
            edit_frame, text="Limpiar A", style="DS3.TButton", command=self._clear_a
        ).pack(side="left", padx=4)
        ttk.Button(
            edit_frame, text="Limpiar B", style="DS3.TButton", command=self._clear_b
        ).pack(side="left", padx=4)

        ttk.Button(
            ops,
            text="Enviar A op B",
            style="DS3.TButton",
            command=self._send_expression,
        ).grid(row=3, column=4, padx=8, pady=(8, 0), sticky="e")

        ops.grid_columnconfigure(1, weight=1)
        ops.grid_columnconfigure(3, weight=1)

        ttk.Separator(container, orient="horizontal", style="DS3.TSeparator").pack(
            fill="x", pady=6
        )

        # ===== Teclado numérico =====
        kb_outer, kb = golden_frame(container, padding=(12, 10))
        kb_outer.pack(pady=(0, 10))

        layout = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", ""],
        ]
        for r, row in enumerate(layout):
            for c, label in enumerate(row):
                if label:
                    ttk.Button(
                        kb,
                        text=label,
                        style="DS3.TButton",
                        width=6,
                        command=lambda x=label: self._append_digit(x),
                    ).grid(row=r, column=c, padx=8, pady=8)
                else:
                    tk.Label(kb, text=" ", bg=COL_PANEL).grid(
                        row=r, column=c, padx=8, pady=8
                    )

        # Atajos de teclado para 0–9
        for ch in "0123456789":
            root.bind(ch, lambda e, x=ch: self._append_digit(x))

        # ===== Cliente serial =====
        self.client = SerialAutoClient(
            on_rx_line=lambda _line: None,
            on_status=self._set_status,
        )
        self.client.start()

        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self._focus_active_entry()

    # ===== Estado =====
    def _set_status(self, text: str):
        self.status_var.set(text)

    # ===== Utilidades de edición =====
    def _focus_active_entry(self):
        if self.active_field.get() == "A":
            self.entry_a.focus_set()
            self.entry_a.icursor("end")
        else:
            self.entry_b.focus_set()
            self.entry_b.icursor("end")

    def _append_digit(self, ch: str):
        if self.active_field.get() == "A":
            self.a_var.set(self.a_var.get() + ch)
        else:
            self.b_var.set(self.b_var.get() + ch)
        self._focus_active_entry()

    def _backspace(self):
        if self.active_field.get() == "A":
            s = self.a_var.get()
            if s:
                self.a_var.set(s[:-1])
        else:
            s = self.b_var.get()
            if s:
                self.b_var.set(s[:-1])
        self._focus_active_entry()

    def _clear_a(self):
        self.a_var.set("")

    def _clear_b(self):
        self.b_var.set("")

    def _force_rescan(self):
        self._set_status("Reescaneando puertos…")
        self.client.force_rescan()

    # ===== Envío de comandos al Arduino =====
    def _send_line_safe(self, line: str):
        if not self.client.is_connected():
            messagebox.showwarning(
                "No conectado",
                "Aún no se ha detectado el dispositivo. Pulsa 'Reintentar'.",
            )
            return
        try:
            self.client.send_line(line)
        except Exception as e:
            messagebox.showerror("Error al enviar", str(e))

    def _send_expression(self):
        """
        Construye y envía la expresión 'A op B', por ejemplo '3+5'.
        El Arduino se encarga de traducirlo a nibbles SPI.
        """
        if not self.client.is_connected():
            messagebox.showwarning(
                "No conectado",
                "Aún no se ha detectado el dispositivo. Pulsa 'Reintentar'.",
            )
            return

        a = self.a_var.get().strip()
        b = self.b_var.get().strip()
        op = self.op_var.get()

        # Restricción: un dígito 0–9 para A y B
        if not (len(a) == 1 and a.isdigit()):
            messagebox.showerror(
                "A inválido", "A debe ser un solo dígito entre 0 y 9."
            )
            return
        if not (len(b) == 1 and b.isdigit()):
            messagebox.showerror(
                "B inválido", "B debe ser un solo dígito entre 0 y 9."
            )
            return

        expr = f"{a}{op}{b}"
        try:
            self.client.send_line(expr)
            self._set_status(f"Enviado: {expr}")
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
    root.minsize(640, 460)
    root.mainloop()


if __name__ == "__main__":
    main()
