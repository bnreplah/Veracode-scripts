#!/usr/bin/env python3
"""
Terminal UI Module - A fully contained terminal interface library
Supports keyboard navigation and mouse clicks for interactive menus and lists

Created by an LLM, has been scanned, but needs to be tested further
"""

import sys
import tty # Need to make sure this is imported
import termios
import os
from typing import List, Optional, Callable, Tuple
from dataclasses import dataclass
from enum import Enum


class Key(Enum):
    """Key codes for terminal input"""
    UP = '\x1b[A'
    DOWN = '\x1b[B'
    RIGHT = '\x1b[C'
    LEFT = '\x1b[D'
    ENTER = '\r'
    SPACE = ' '
    ESC = '\x1b'
    TAB = '\t'
    BACKSPACE = '\x7f'
    CTRL_C = '\x03'


@dataclass
class MouseEvent:
    """Mouse event data"""
    x: int
    y: int
    button: int  # 0=left, 1=middle, 2=right
    pressed: bool


class TerminalUI:
    """Base class for terminal UI operations"""
    
    def __init__(self):
        self.old_settings = None
        self.mouse_enabled = False
        
    def __enter__(self):
        """Context manager entry - setup terminal"""
        self.setup()
        return self
        
    def __exit__(self, *args):
        """Context manager exit - restore terminal"""
        self.restore()
        
    def setup(self):
        """Setup terminal for raw input"""
        self.old_settings = termios.tcgetattr(sys.stdin)
        tty.setraw(sys.stdin.fileno())
        self.hide_cursor()
        
    def restore(self):
        """Restore terminal to normal mode"""
        if self.old_settings:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old_settings)
        self.show_cursor()
        if self.mouse_enabled:
            self.disable_mouse()
            
    def enable_mouse(self):
        """Enable mouse tracking"""
        sys.stdout.write('\x1b[?1000h')  # Enable mouse tracking
        sys.stdout.write('\x1b[?1002h')  # Enable cell motion tracking
        sys.stdout.write('\x1b[?1015h')  # Enable urxvt mouse mode
        sys.stdout.write('\x1b[?1006h')  # Enable SGR mouse mode
        sys.stdout.flush()
        self.mouse_enabled = True
        
    def disable_mouse(self):
        """Disable mouse tracking"""
        sys.stdout.write('\x1b[?1000l')
        sys.stdout.write('\x1b[?1002l')
        sys.stdout.write('\x1b[?1015l')
        sys.stdout.write('\x1b[?1006l')
        sys.stdout.flush()
        self.mouse_enabled = False
        
    def hide_cursor(self):
        """Hide terminal cursor"""
        sys.stdout.write('\x1b[?25l')
        sys.stdout.flush()
        
    def show_cursor(self):
        """Show terminal cursor"""
        sys.stdout.write('\x1b[?25h')
        sys.stdout.flush()
        
    def clear_screen(self):
        """Clear the terminal screen"""
        sys.stdout.write('\x1b[2J')
        sys.stdout.flush()
        
    def move_cursor(self, x: int, y: int):
        """Move cursor to position (x, y)"""
        sys.stdout.write(f'\x1b[{y};{x}H')
        sys.stdout.flush()
        
    def get_terminal_size(self) -> Tuple[int, int]:
        """Get terminal size (width, height)"""
        size = os.get_terminal_size()
        return size.columns, size.lines
        
    def read_input(self) -> str:
        """Read a single input (key or sequence)"""
        ch = sys.stdin.read(1)
        
        # Handle escape sequences
        if ch == '\x1b':
            ch += sys.stdin.read(1)
            if ch[-1] == '[':
                # Arrow keys or mouse
                next_ch = sys.stdin.read(1)
                ch += next_ch
                
                # Check for mouse event (SGR format)
                if next_ch == '<':
                    while True:
                        c = sys.stdin.read(1)
                        ch += c
                        if c in 'mM':
                            break
                # Extended sequences (might have more chars)
                elif next_ch.isdigit():
                    while True:
                        c = sys.stdin.read(1)
                        ch += c
                        if c.isalpha() or c == '~':
                            break
        
        return ch
        
    def parse_mouse_event(self, seq: str) -> Optional[MouseEvent]:
        """Parse mouse event from escape sequence"""
        if not seq.startswith('\x1b[<'):
            return None
            
        try:
            # SGR format: \x1b[<B;X;YM or \x1b[<B;X;Ym
            data = seq[3:-1]  # Remove \x1b[< and M/m
            parts = data.split(';')
            
            if len(parts) != 3:
                return None
                
            button = int(parts[0])
            x = int(parts[1])
            y = int(parts[2])
            pressed = seq[-1] == 'M'
            
            # Button mapping (0=left, 1=middle, 2=right)
            button = button & 0x3
            
            return MouseEvent(x=x, y=y, button=button, pressed=pressed)
        except:
            return None


class Selector(TerminalUI):
    """Interactive selector for choosing from a list of options"""
    
    def __init__(self, options: List[str], title: str = "Select an option:",
                 pointer: str = "→", allow_mouse: bool = True):
        super().__init__()
        self.options = options
        self.title = title
        self.pointer = pointer
        self.selected = 0
        self.allow_mouse = allow_mouse
        
    def render(self):
        """Render the selector UI"""
        self.clear_screen()
        self.move_cursor(1, 1)
        
        # Print title
        sys.stdout.write(f"\x1b[1m{self.title}\x1b[0m\n\n")
        
        # Print options
        for i, option in enumerate(self.options):
            if i == self.selected:
                # Highlighted option
                sys.stdout.write(f"  \x1b[1;32m{self.pointer} {option}\x1b[0m\n")
            else:
                sys.stdout.write(f"    {option}\n")
                
        # Instructions
        sys.stdout.write(f"\n\x1b[2mUse ↑/↓ or mouse, Enter to select, ESC to cancel\x1b[0m")
        sys.stdout.flush()
        
    def get_option_at_line(self, line: int) -> Optional[int]:
        """Get option index at given line number"""
        # Title takes 2 lines (title + blank)
        option_start = 3
        option_line = line - option_start
        
        if 0 <= option_line < len(self.options):
            return option_line
        return None
        
    def run(self) -> Optional[int]:
        """Run the selector and return selected index (or None if cancelled)"""
        with self:
            if self.allow_mouse:
                self.enable_mouse()
                
            self.render()
            
            while True:
                inp = self.read_input()
                
                # Handle mouse input
                if inp.startswith('\x1b[<'):
                    mouse = self.parse_mouse_event(inp)
                    if mouse and mouse.pressed and mouse.button == 0:  # Left click
                        option = self.get_option_at_line(mouse.y)
                        if option is not None:
                            self.selected = option
                            self.render()
                            # Double-click simulation: immediate selection
                            return self.selected
                    continue
                
                # Handle keyboard input
                if inp == Key.UP.value:
                    self.selected = (self.selected - 1) % len(self.options)
                    self.render()
                elif inp == Key.DOWN.value:
                    self.selected = (self.selected + 1) % len(self.options)
                    self.render()
                elif inp == Key.ENTER.value or inp == ' ':
                    return self.selected
                elif inp == Key.ESC.value or inp == Key.CTRL_C.value:
                    return None
                    
        return None


class Menu(TerminalUI):
    """Interactive menu with customizable actions"""
    
    def __init__(self, items: List[Tuple[str, Callable]], 
                 title: str = "Menu:", allow_mouse: bool = True):
        super().__init__()
        self.items = items  # List of (label, callback) tuples
        self.title = title
        self.selected = 0
        self.allow_mouse = allow_mouse
        self.running = True
        
    def render(self):
        """Render the menu UI"""
        self.clear_screen()
        self.move_cursor(1, 1)
        
        sys.stdout.write(f"\x1b[1m{self.title}\x1b[0m\n\n")
        
        for i, (label, _) in enumerate(self.items):
            if i == self.selected:
                sys.stdout.write(f"  \x1b[1;36m▶ {label}\x1b[0m\n")
            else:
                sys.stdout.write(f"    {label}\n")
                
        sys.stdout.write(f"\n\x1b[2mNavigate: ↑/↓, Select: Enter, Exit: ESC\x1b[0m")
        sys.stdout.flush()
        
    def get_item_at_line(self, line: int) -> Optional[int]:
        """Get menu item index at given line"""
        item_start = 3
        item_line = line - item_start
        
        if 0 <= item_line < len(self.items):
            return item_line
        return None
        
    def run(self):
        """Run the menu"""
        with self:
            if self.allow_mouse:
                self.enable_mouse()
                
            self.render()
            
            while self.running:
                inp = self.read_input()
                
                if inp.startswith('\x1b[<'):
                    mouse = self.parse_mouse_event(inp)
                    if mouse and mouse.pressed and mouse.button == 0:
                        item = self.get_item_at_line(mouse.y)
                        if item is not None:
                            self.selected = item
                            _, callback = self.items[self.selected]
                            self.restore()
                            callback()
                            if self.running:
                                self.setup()
                                if self.allow_mouse:
                                    self.enable_mouse()
                                self.render()
                    continue
                
                if inp == Key.UP.value:
                    self.selected = (self.selected - 1) % len(self.items)
                    self.render()
                elif inp == Key.DOWN.value:
                    self.selected = (self.selected + 1) % len(self.items)
                    self.render()
                elif inp == Key.ENTER.value:
                    _, callback = self.items[self.selected]
                    self.restore()
                    callback()
                    if self.running:
                        self.setup()
                        if self.allow_mouse:
                            self.enable_mouse()
                        self.render()
                elif inp == Key.ESC.value or inp == Key.CTRL_C.value:
                    self.running = False
                    
    def stop(self):
        """Stop the menu"""
        self.running = False


# Demo and usage examples
if __name__ == "__main__":
    
    def demo_selector():
        """Demo the selector"""
        options = [
            "Option 1: Do something",
            "Option 2: Do something else",
            "Option 3: Another choice",
            "Option 4: Exit"
        ]
        
        selector = Selector(options, title="Choose an action:")
        result = selector.run()
        
        if result is not None:
            print(f"\nYou selected: {options[result]}")
        else:
            print("\nSelection cancelled")
    
    def demo_menu():
        """Demo the menu"""
        def action1():
            print("\n\x1b[1;32m✓ Action 1 executed!\x1b[0m")
            input("Press Enter to continue...")
            
        def action2():
            print("\n\x1b[1;33m⚡ Action 2 executed!\x1b[0m")
            input("Press Enter to continue...")
            
        def action3():
            items = ["Apple", "Banana", "Cherry", "Date"]
            sel = Selector(items, title="Pick a fruit:")
            choice = sel.run()
            if choice is not None:
                print(f"\n\x1b[1;35m🍎 You picked: {items[choice]}\x1b[0m")
                input("Press Enter to continue...")
        
        menu = Menu([
            ("Action 1", action1),
            ("Action 2", action2),
            ("Nested Selector", action3),
            ("Exit", lambda: menu.stop())
        ], title="Main Menu")
        
        menu.run()
        print("\nGoodbye!")
    
    # Run demos
    print("Terminal UI Module Demo\n")
    print("1. Selector Demo")
    print("2. Menu Demo")
    choice = input("\nChoose demo (1 or 2): ")
    
    if choice == "1":
        demo_selector()
    elif choice == "2":
        demo_menu()
    else:
        print("Invalid choice")