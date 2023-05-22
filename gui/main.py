#! /usr/bin/env python3
import sys
import re
import os
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont, QTextCursor, QKeySequence, QSyntaxHighlighter, QTextCharFormat, QColor
from PyQt5.QtWidgets import QLabel, QApplication, QHBoxLayout, QVBoxLayout, QTextEdit, QWidget, QShortcut, QFileDialog, QPushButton, QTextBrowser


# Regex patterns for output file parsing
lexer_line_pattern = r'Lex\(\d+\).+'
quads_line_pattern = r'Quads\(\).+'
successful_execution_pattern = r'Lex\(\d+\) command: exit'
error_line_pattern = r'Lex\((\d+)\).+'


# Application customizations
TITLE_STYLE_SHEET = "font-size: 30px; font-weight: bold; color: #0BB419;"
TEXT_EDITOR_FONT_SIZE = 20
TEXT_EDITOR_WIDTH = 750
TEXT_EDITOR_HEIGHT = 600
CODE_FONT_FAMILY = "Hack"
CODE_COLOR = "#000000"
LINE_NUMBER_COLOR = "#0000FF"
BUTTON_STYLE_SHEET = "background-color: #0BB419; color: white; font-size: 30px; font-weight: bold"
BUTTON_WIDTH = 250
BUTTON_HEIGHT = 100


class LineNumberWidget(QTextBrowser):
    def __init__(self, widget, number_color, font_size):
        super().__init__()
        self.__number_color = number_color
        self.__initUi(widget, font_size)

    def __initUi(self, widget, font_size):
        self.__lineCount = widget.document().lineCount()
        self.__size = font_size
        self.__styleInit()

        self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setTextInteractionFlags(Qt.NoTextInteraction)

        self.verticalScrollBar().setEnabled(False)

        widget.verticalScrollBar().valueChanged.connect(self.__changeLineWidgetScrollAsTargetedWidgetScrollChanged)

        self.__initLineCount()

    def __changeLineWidgetScrollAsTargetedWidgetScrollChanged(self, v):
        self.verticalScrollBar().setValue(v)

    def __initLineCount(self):
        for n in range(1, self.__lineCount+1):
            self.append(str(n))

    def changeLineCount(self, n):
        max_one = max(self.__lineCount, n)
        diff = n-self.__lineCount
        if max_one == self.__lineCount:
            first_v = self.verticalScrollBar().value()
            for i in range(self.__lineCount, self.__lineCount + diff, -1):
                self.moveCursor(QTextCursor.End, QTextCursor.MoveAnchor)
                self.moveCursor(QTextCursor.StartOfLine, QTextCursor.MoveAnchor)
                self.moveCursor(QTextCursor.End, QTextCursor.KeepAnchor)
                self.textCursor().removeSelectedText()
                self.textCursor().deletePreviousChar()
            last_v = self.verticalScrollBar().value()
            if abs(first_v-last_v) != 2:
                self.verticalScrollBar().setValue(first_v)
        else:
            for i in range(self.__lineCount, self.__lineCount + diff, 1):
                self.append(str(i + 1))

        self.__lineCount = n

    def setValue(self, v):
        self.verticalScrollBar().setValue(v)

    def setFontSize(self, s: float):
        self.__size = int(s)
        self.__styleInit()

    def __styleInit(self):
        self.__style = f'''
                       QTextBrowser 
                       {{ 
                       background: transparent; 
                       border: none; 
                       color: {self.__number_color}; 
                       font: {self.__size}pt;
                       }}
                       '''
        self.setStyleSheet(self.__style)
        self.setFixedWidth(self.__size*5)


class SyntaxHighlighter(QSyntaxHighlighter):
    def __init__(self, parent):
        super(SyntaxHighlighter, self).__init__(parent)
        self._highlight_lines = dict()

    def highlight_line(self, line, fmt):
        if isinstance(line, int) and line >= 0 and isinstance(fmt, QTextCharFormat):
            self._highlight_lines[line] = fmt
            tb = self.document().findBlockByLineNumber(line)
            self.rehighlightBlock(tb)

    def clear_highlight(self):
        self._highlight_lines = dict()
        self.rehighlight()

    def highlightBlock(self, text):
        line = self.currentBlock().blockNumber()
        fmt = self._highlight_lines.get(line)
        if fmt is not None:
            self.setFormat(0, len(text), fmt)


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()

        self.file_path = None

        self.open_new_file_shortcut = QShortcut(QKeySequence('Ctrl+O'), self)
        self.open_new_file_shortcut.activated.connect(self.open_new_file)

        self.save_current_file_shortcut = QShortcut(QKeySequence('Ctrl+S'), self)
        self.save_current_file_shortcut.activated.connect(self.save_current_file)


        self.style_layout()
        self.highlighter = SyntaxHighlighter(self.code_text_editor.document())

        # Make the window full screen
        self.showMaximized()


    def style_layout(self):
        code_layout = self.create_code_area()
        error_layout = self.create_compilation_area()
        quads_layout = self.create_quads_area()
        symbol_table_layout = self.create_symbol_table_area()

        left_half_app_layout = QVBoxLayout()
        left_half_app_layout.addLayout(code_layout)
        left_half_app_layout.addLayout(error_layout, 1)

        right_half_layout = QVBoxLayout()
        right_half_layout.addLayout(quads_layout)
        right_half_layout.addLayout(symbol_table_layout, 1)

        app_layout = QHBoxLayout()
        app_layout.addLayout(left_half_app_layout)
        app_layout.addLayout(right_half_layout, 1)

        self.setLayout(app_layout)


    def create_code_area(self):
        # Create title widget
        text_editor_title = QLabel("Source Code")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(350, 0, 0, 0)

        # Create the text editor widget
        self.code_text_editor = QTextEdit()
        self.code_text_editor.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        self.code_text_editor.setStyleSheet(f"color: {CODE_COLOR};")

        # Make the text editor scrollable
        self.code_text_editor.setLineWrapMode(QTextEdit.NoWrap)

        # Change the font family of the text editor to be code friendly
        self.code_text_editor.setFont(QFont(CODE_FONT_FAMILY))
        
        # Change the size of the text editor
        self.code_text_editor.setFixedWidth(TEXT_EDITOR_WIDTH)
        self.code_text_editor.setFixedHeight(TEXT_EDITOR_HEIGHT)

        # Add an event handler to the text editor to trace the line number
        self.code_text_editor.textChanged.connect(self.line_widget_line_count_changed)

        self.line_widget = LineNumberWidget(self.code_text_editor, number_color=LINE_NUMBER_COLOR, font_size=TEXT_EDITOR_FONT_SIZE)
        self.line_widget.setFixedHeight(TEXT_EDITOR_HEIGHT)

        text_editor_layout = QHBoxLayout()
        text_editor_layout.addWidget(self.line_widget)
        text_editor_layout.addWidget(self.code_text_editor)
        text_editor_layout.setAlignment(self.code_text_editor, Qt.AlignTop | Qt.AlignLeft)

        compile_button = QPushButton("Compile") 
        compile_button.setFixedWidth(BUTTON_WIDTH)
        compile_button.setFixedHeight(BUTTON_HEIGHT)
        compile_button.setStyleSheet(BUTTON_STYLE_SHEET)
        # Add an event handler to the button
        compile_button.clicked.connect(self.compile_button_handler) 

        compile_button_layout = QHBoxLayout()
        compile_button_layout.addWidget(compile_button)
        compile_button_layout.setContentsMargins(340, 10, 0, 0)
        compile_button_layout.setAlignment(compile_button, Qt.AlignTop | Qt.AlignLeft)

        code_layout = QVBoxLayout()
        code_layout.addWidget(text_editor_title)
        code_layout.addLayout(text_editor_layout, 1)
        code_layout.addLayout(compile_button_layout, 2)

        return code_layout
    

    def create_compilation_area(self):
        text_editor_title = QLabel("Compilation Output")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(200, 0, 0, 0)

        self.error_editor = QTextEdit()
        self.error_editor.setReadOnly(True)
        self.error_editor.setViewportMargins(20, 20, 20, 20)

        # Change the font size of the text editor
        self.error_editor.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        self.error_editor.setStyleSheet(f"color: #FFF; background-color: #000;")

        # Make the text editor scrollable
        self.error_editor.setLineWrapMode(QTextEdit.NoWrap)

        # Change the font family of the text editor to be code friendly
        self.error_editor.setFontFamily(CODE_FONT_FAMILY)
        
        # Change the size of the text editor
        self.error_editor.setFixedWidth(TEXT_EDITOR_WIDTH)
        self.error_editor.setFixedHeight(400)

        error_layout = QVBoxLayout()
        error_layout.setContentsMargins(110, 70, 0, 0)
        error_layout.addWidget(text_editor_title)
        error_layout.addWidget(self.error_editor)
        return error_layout
    

    def create_quads_area(self):
        text_editor_title = QLabel("Quadruples")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(600, 0, 0, 0)

        self.quads_editor = QTextEdit()
        self.quads_editor.setReadOnly(True)

        # Change the font size of the text editor
        self.quads_editor.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        self.quads_editor.setStyleSheet(f"color: {CODE_COLOR};")

        # Make the text editor scrollable
        self.quads_editor.setLineWrapMode(QTextEdit.NoWrap)

        # Change the font family of the text editor to be code friendly
        self.quads_editor.setFontFamily(CODE_FONT_FAMILY)

        # Change the size of the text editor
        self.quads_editor.setFixedWidth(TEXT_EDITOR_WIDTH)
        self.quads_editor.setFixedHeight(TEXT_EDITOR_HEIGHT)

        quads_layout = QVBoxLayout()
        quads_layout.setContentsMargins(0, 0, 170, 40)
        quads_layout.addWidget(text_editor_title)
        quads_layout.addWidget(self.quads_editor, 1)
        quads_layout.setAlignment(text_editor_title, Qt.AlignTop)
        quads_layout.setAlignment(self.quads_editor, Qt.AlignTop | Qt.AlignRight)
        return quads_layout
    

    def create_symbol_table_area(self):
        text_editor_title = QLabel("Symbol Table")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(600, 170, 0, 0)

        self.symbol_table = QTextEdit()
        self.symbol_table.setReadOnly(True)

        # Change the font size of the text editor
        self.symbol_table.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        self.symbol_table.setStyleSheet(f"color: {CODE_COLOR};")

        # Make the text editor scrollable
        self.symbol_table.setLineWrapMode(QTextEdit.NoWrap)
        
        # Change the size of the text editor
        self.symbol_table.setFixedWidth(TEXT_EDITOR_WIDTH)
        self.symbol_table.setFixedHeight(400)

        symbol_table_layout = QVBoxLayout()
        symbol_table_layout.setContentsMargins(0, 0, 170, 0)
        symbol_table_layout.addWidget(text_editor_title)
        symbol_table_layout.addWidget(self.symbol_table, 1)
        symbol_table_layout.setAlignment(self.symbol_table, Qt.AlignTop)
        symbol_table_layout.setAlignment(self.symbol_table, Qt.AlignTop | Qt.AlignRight)
        return symbol_table_layout

    
    def compile_button_handler(self):
        self.error_editor.setText("")
        self.quads_editor.setText("")
        self.highlighter.clear_highlight()
        file_contents = self.code_text_editor.toPlainText()
        with open("../test/temp.c", "w") as f:
            f.write(file_contents)

        os.chdir('..')
        # os.system('make build')
        # os.system('./main < ./test/temp.c > ./test/out/temp.out')
        with open('./test/out/temp.out', "r") as f:
            output = f.read().splitlines()

        lexer_lines = []
        quads_lines = []
        console_lines = []
        for line in output:
            if re.match(lexer_line_pattern, line):
                lexer_lines.append(line)
            elif re.match(quads_line_pattern, line):
                quads_lines.append(line.replace('Quads() ', ''))
            elif line != '':
                console_lines.append(line)


        if re.match(successful_execution_pattern, lexer_lines[-1]):
            console_lines.append('Compilation successful')
        else:
            error_line = int(re.search(error_line_pattern, lexer_lines[-1]).group(1)) - 1
            console_lines.append(f'Syntax error at line ({error_line + 1})')
            print(error_line)
            fmt = QTextCharFormat()
            fmt.setBackground(QColor(255, 0, 0))
            self.highlighter.clear_highlight()
            self.highlighter.highlight_line(error_line, fmt)


        self.error_editor.setText('\n'.join(console_lines))
        self.quads_editor.setText('\n'.join(quads_lines))
        os.chdir('gui')
        # os.remove('../test/temp.c')
        # os.remove('../test/out/temp.out')
        

    def line_widget_line_count_changed(self):
        self.code_text_editor.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        if self.line_widget:
            n = int(self.code_text_editor.document().lineCount())
            self.line_widget.changeLineCount(n)


    def open_new_file(self):
        self.file_path, _ = QFileDialog.getOpenFileName(self, "Open a new file", "", "*.c")
        if self.file_path:
            with open(self.file_path, "r") as f:
                file_contents = f.read()
                # self.title.setText(self.file_path)
                self.code_text_editor.setText(file_contents)
        else:
            # self.invalid_path_alert_message()
            pass


    def save_current_file(self):
        if not self.file_path:
            new_file_path, _ = QFileDialog.getSaveFileName(self, "Save file as", "", "*.c")
            if new_file_path:
                self.file_path = new_file_path
            else:
                # self.invalid_path_alert_message()
                return False
        file_contents = self.code_text_editor.toPlainText()
        with open(self.file_path, "w") as f:
            f.write(file_contents)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    mainWindow = MainWindow()
    mainWindow.show()
    app.exec()