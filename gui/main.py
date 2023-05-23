#! /usr/bin/env python3
import sys
import re
import os
from PyQt5.QtCore import Qt, QRegExp
from PyQt5.QtGui import QFont, QTextCursor, QKeySequence, QSyntaxHighlighter, QTextCharFormat, QColor, QPixmap
from PyQt5.QtWidgets import QLabel, QApplication, QHBoxLayout, QVBoxLayout, QTextEdit, QWidget, QShortcut, QFileDialog, QPushButton, QTextBrowser, QTableWidget, QTableWidgetItem, QAbstractItemView


# Regex patterns for output file parsing
lexer_line_pattern = r'Lex\((\d+)\).+'
quads_line_pattern = r'Quads\(.*\).+'
syntax_error_line_pattern = r'Syntax error \((\d+)\).+'
semantic_error_line_pattern = r'Semantic error \((\d+)\).+'
semantic_warning_line_pattern = r'Semantic warning \((\d+)\).+'


# Application customizations
TITLE_STYLE_SHEET = "font-size: 30px; font-weight: bold; color: #0BB419;"
TEXT_EDITOR_FONT_SIZE = 20
TEXT_EDITOR_WIDTH = 750
TEXT_EDITOR_HEIGHT = 600
CODE_FONT_FAMILY = "Courier New"
CODE_COLOR = "#000000"
LINE_NUMBER_COLOR = "#0000FF"
BUTTON_STYLE_SHEET = "background-color: #0BB419; color: white; font-size: 30px; font-weight: bold"
BUTTON_WIDTH = 230
BUTTON_HEIGHT = 100


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()

        self.file_path = None
        self.symbol_table_headers = ['Name', 'Type', 'Value', 'Declared', 'Initialized', 'Used', 'Scope']
        self.current_line = 1

        self.open_new_file_shortcut = QShortcut(QKeySequence('Ctrl+O'), self)
        self.open_new_file_shortcut.activated.connect(self.open_new_file)

        self.save_current_file_shortcut = QShortcut(QKeySequence('Ctrl+S'), self)
        self.save_current_file_shortcut.activated.connect(self.save_current_file)

        self.style_layout()
        self.highlighter = CCodeHighlighter(self.code_text_editor.document())
        self.remove_highlight_button.clicked.connect(lambda: self.highlighter.clear_highlight())

        # Make the window full screen
        self.showMaximized()

        # Change the title of the window
        self.setWindowTitle("C+- Compiler")

        # Change the background color of the window
        # self.setStyleSheet("background-color: #FFFFFF;")

        # print the resolution of the screen
        # print("Resolution:", QApplication.desktop().screenGeometry())


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

        center_app_layout = self.create_center_area()

        app_layout = QHBoxLayout()
        app_layout.addLayout(left_half_app_layout)
        app_layout.addWidget(center_app_layout, 1)
        app_layout.addLayout(right_half_layout, 2)

        self.setLayout(app_layout)

    def create_center_area(self):
        label = QLabel("Cover")
        pixmap = QPixmap('logo.png')
        pixmap = pixmap.scaledToHeight(180)
        pixmap = pixmap.scaledToWidth(280)
        label.setPixmap(pixmap)
        layout = QVBoxLayout()
        layout.addWidget(label)
        # label.setAlignment(Qt.AlignCenter)
        label.setContentsMargins(35, 250, 0, 0)
        return label

    def create_code_area(self):
        # Create title widget
        text_editor_title = QLabel("Source Code")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(350, 0, 0, 0)

        # Create remove highlight button
        self.remove_highlight_button = QPushButton("R")
        self.remove_highlight_button.setFixedWidth(40)
        self.remove_highlight_button.setFixedHeight(44)
        self.remove_highlight_button.setStyleSheet(BUTTON_STYLE_SHEET)
        self.remove_highlight_button.setToolTip("Remove Syntax Highlight")
        self.remove_highlight_button.setShortcut("Ctrl+R")

        title_layout = QHBoxLayout()
        title_layout.addWidget(text_editor_title)
        title_layout.addWidget(self.remove_highlight_button) 

        # Create the text editor widget
        self.code_text_editor = CodeEditor()
        self.code_text_editor.setFont(QFont(CODE_FONT_FAMILY, TEXT_EDITOR_FONT_SIZE + 1))
        self.code_text_editor.setStyleSheet(f"color: {CODE_COLOR};")
        
        # Change the size of the text editor
        self.code_text_editor.setFixedWidth(TEXT_EDITOR_WIDTH)
        self.code_text_editor.setFixedHeight(TEXT_EDITOR_HEIGHT)

        self.line_widget = LineNumberWidget(self.code_text_editor, number_color=LINE_NUMBER_COLOR, font_size=TEXT_EDITOR_FONT_SIZE)
        self.line_widget.setFixedHeight(TEXT_EDITOR_HEIGHT)
        self.code_text_editor.textChanged.connect(self.line_widget_line_count_changed)

        text_editor_layout = QHBoxLayout()
        text_editor_layout.addWidget(self.line_widget)
        text_editor_layout.addWidget(self.code_text_editor)
        text_editor_layout.setAlignment(self.code_text_editor, Qt.AlignTop | Qt.AlignLeft)

        compile_all_button = QPushButton("Compile All") 
        compile_all_button.setFixedWidth(BUTTON_WIDTH)
        compile_all_button.setFixedHeight(BUTTON_HEIGHT)
        compile_all_button.setStyleSheet(BUTTON_STYLE_SHEET)
        # Add an event handler to the button
        compile_all_button.clicked.connect(self.compile_all_button_handler)

        self.compile_step_by_step_button = QPushButton(f"Compile Step by Step ({-1})")
        self.compile_step_by_step_button.setFixedWidth(BUTTON_WIDTH + 250)
        self.compile_step_by_step_button.setFixedHeight(BUTTON_HEIGHT)
        self.compile_step_by_step_button.setStyleSheet(BUTTON_STYLE_SHEET)
        # Add an event handler to the button
        self.compile_step_by_step_button.clicked.connect(self.compile_step_by_step_button_handler)

        buttons_layout = QHBoxLayout()
        buttons_layout.setSpacing(10)
        buttons_layout.addWidget(compile_all_button)
        buttons_layout.addWidget(self.compile_step_by_step_button)
        buttons_layout.setContentsMargins(105, 20, 0, 0)

        code_layout = QVBoxLayout()
        code_layout.addLayout(title_layout)
        code_layout.addLayout(text_editor_layout, 1)
        code_layout.addLayout(buttons_layout, 2)

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
        text_editor_title.setContentsMargins(0, 0, 280, 5)

        self.quads_editor = QTextEdit()

        # Change the font size of the text editor
        self.quads_editor.setFontPointSize(TEXT_EDITOR_FONT_SIZE)
        self.quads_editor.setStyleSheet(f"color: {CODE_COLOR};")

        self.quads_editor.setReadOnly(True)

        # Make the text editor scrollable
        self.quads_editor.setLineWrapMode(QTextEdit.NoWrap)

        # Change the font family of the text editor to be code friendly
        self.quads_editor.setFontFamily(CODE_FONT_FAMILY)

        # Change the size of the text editor
        self.quads_editor.setFixedWidth(TEXT_EDITOR_WIDTH + 70)
        self.quads_editor.setFixedHeight(TEXT_EDITOR_HEIGHT)

        quads_layout = QVBoxLayout()
        quads_layout.setContentsMargins(0, 0, 100, 40)
        quads_layout.addWidget(text_editor_title)
        quads_layout.addWidget(self.quads_editor, 1)
        quads_layout.setAlignment(text_editor_title, Qt.AlignTop | Qt.AlignRight)
        quads_layout.setAlignment(self.quads_editor, Qt.AlignTop | Qt.AlignRight)

        return quads_layout
    

    def create_symbol_table_area(self):
        text_editor_title = QLabel("Symbol Table")
        text_editor_title.setStyleSheet(TITLE_STYLE_SHEET)
        text_editor_title.setContentsMargins(330, 170, 0, 0)

        self.symbol_table = QTableWidget()
        self.symbol_table.setStyleSheet(f"color: {CODE_COLOR};")
        self.symbol_table.setFont(QFont(CODE_FONT_FAMILY, TEXT_EDITOR_FONT_SIZE - 5))
        self.symbol_table.setEditTriggers(QAbstractItemView.NoEditTriggers)

        self.symbol_table.setColumnCount(7)
        self.symbol_table.setHorizontalHeaderLabels(self.symbol_table_headers)
        self.symbol_table.setColumnWidth(2, 120)
        self.symbol_table.setColumnWidth(3, 120)
        self.symbol_table.setColumnWidth(4, 140)
        
        # Change the size of the table
        self.symbol_table.setFixedWidth(TEXT_EDITOR_WIDTH + 70)
        self.symbol_table.setFixedHeight(400)

        # Change the font size of the headers
        self.symbol_table.horizontalHeader().setFont(QFont(CODE_FONT_FAMILY, TEXT_EDITOR_FONT_SIZE - 5))

        symbol_table_layout = QVBoxLayout()
        symbol_table_layout.setContentsMargins(0, 0, 100, 0)
        symbol_table_layout.addWidget(text_editor_title)
        symbol_table_layout.addWidget(self.symbol_table, 1)
        symbol_table_layout.setAlignment(self.symbol_table, Qt.AlignTop | Qt.AlignRight)
        symbol_table_layout.setAlignment(self.symbol_table, Qt.AlignTop | Qt.AlignRight)

        return symbol_table_layout

    
    def compile_all_button_handler(self):
        self.current_line = 1
        self.compile_step_by_step_button.setText(f"Compile Step by Step ({-1})")
        # Reset the output fields
        self.error_editor.setText("Compiling...")
        self.quads_editor.setText("")
        self.highlighter.clear_highlight()
        self.symbol_table.clearContents()
        self.symbol_table.setRowCount(0)

        # Referesh the window
        self.repaint()

        # Export the written code to a temporary file
        os.chdir('..')
        file_contents = self.code_text_editor.toPlainText()
        with open("test/temp.c", "w") as f:
            f.write(file_contents)

        # Compile the code
        os.system('make build')
        os.system('./main < ./test/temp.c > ./test/out/temp.out')
        
        # Parse the output files
        self.parse_output_file()
        self.parse_symbol_table()
        
        # Remove the temporary files and return to the working directory
        os.remove('test/temp.c')
        # os.remove('test/out/temp.out')
        os.chdir('gui')


    def compile_step_by_step_button_handler(self):
        self.highlighter.clear_highlight()
        # Export the written code to a temporary file
        os.chdir('..')
        code = self.code_text_editor.toPlainText().splitlines()
        file_contents = []
        i = 0
        code_statements = 0
        while True:
            if i >= len(code):
                break
            file_contents.append(code[i])
            if code[i].strip() != '':
                code_statements += 1
            if code_statements == self.current_line:
                self.current_line += 1
                break
            i += 1

        with open("test/temp.c", "w") as f:
            f.write('\n'.join(file_contents))

        # Compile the code
        # os.system('make build')
        os.system('./main < ./test/temp.c > ./test/out/temp.out')
        
        self.compile_step_by_step_button.setText(f"Compile Step by Step ({i + 1})")
        # Parse the output files
        error = self.parse_output_file()
        self.parse_symbol_table()

        if len(file_contents) == len(code) and not error:
            self.error_editor.setText(self.error_editor.toPlainText() + "\nCompilation finished successfully!")
            self.current_line = 1
            
        if error:
            self.current_line = 1

        os.chdir('gui')
        

    def parse_output_file(self):
        # Parse the output file to produce output, highlight erros, and produce quadruples
        with open('test/out/temp.out', "r") as f:
            output = f.read().splitlines()

        lexer_lines = []
        quads_lines = []
        console_lines = []
        for line in output:
            if re.match(lexer_line_pattern, line):
                lexer_lines.append(line)
            elif re.match(quads_line_pattern, line):
                quads_lines.append(re.sub(r'Quads\(.*\)', '', line))
            elif line != '':
                console_lines.append(line)
        
        error = False
        for console_line in console_lines:
            if re.match(syntax_error_line_pattern, console_line):
                error_line = int(re.search(syntax_error_line_pattern, console_line).group(1))
                fmt = QTextCharFormat()
                fmt.setBackground(QColor(255, 0, 0))
                self.highlighter.highlight_line(error_line - 1, fmt)
                error = True
        
        for console_line in console_lines:
            if re.match(semantic_error_line_pattern, console_line):
                error_line = int(re.search(semantic_error_line_pattern, console_line).group(1))
                if error_line - 1 not in self.highlighter.highlight_lines.keys():
                    fmt = QTextCharFormat()
                    fmt.setBackground(QColor(255, 255, 0))
                    self.highlighter.highlight_line(error_line - 1, fmt)
        
        for console_line in console_lines:
            if re.match(semantic_warning_line_pattern, console_line):
                error_line = int(re.search(semantic_warning_line_pattern, console_line).group(1))
                if error_line - 1 not in self.highlighter.highlight_lines.keys():
                    fmt = QTextCharFormat()
                    fmt.setBackground(QColor(255, 165, 0))
                    self.highlighter.highlight_line(error_line - 1, fmt)

        self.error_editor.setText('\n'.join(console_lines))
        self.quads_editor.setText('\n'.join(quads_lines))
        self.repaint()
        return error


    def parse_symbol_table(self):
        # Parse the symbol table
        symbol_table = []
        with open('symbol_table.txt', "r") as f:
            output = f.read().splitlines()
        for line in output:
            if line != 'Symbol Table:' and line.strip() != '':
                temp_map = {}
                elements = line.split(',')
                for element in elements:
                    key, value = element.split(':')
                    temp_map[key] = value
                symbol_table.append(temp_map)
        
        self.symbol_table.setRowCount(len(symbol_table))
        
        row_index = 0
        for row in symbol_table:
            for i, header in enumerate(self.symbol_table_headers):
                item = QTableWidgetItem(row[header])
                item.setTextAlignment(Qt.AlignCenter)
                self.symbol_table.setItem(row_index, i, item)
            row_index += 1


    def line_widget_line_count_changed(self):
        if self.line_widget:
            n = int(self.code_text_editor.document().lineCount())
            self.line_widget.changeLineCount(n)


    def open_new_file(self):
        self.file_path, _ = QFileDialog.getOpenFileName(self, "Open a new file", "", "*.c")
        if self.file_path:
            with open(self.file_path, "r") as f:
                file_contents = f.read()
                self.code_text_editor.setText(file_contents)


    def save_current_file(self):
        if not self.file_path:
            new_file_path, _ = QFileDialog.getSaveFileName(self, "Save file as", "", "*.c")
            if new_file_path:
                self.file_path = new_file_path
        
        file_contents = self.code_text_editor.toPlainText()
        with open(self.file_path, "w") as f:
            f.write(file_contents)


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


class CCodeHighlighter(QSyntaxHighlighter):
    def __init__(self, parent=None):
        super(CCodeHighlighter, self).__init__(parent)
        
        # Define the C keywords
        self.keywords = [
            'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 'extern',
            'float', 'for', 'goto', 'if', 'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof', 'static',
            'struct', 'switch', 'typedef', 'union', 'unsigned', 'void', 'volatile', 'while', 'print'
        ]
        
        # Define the C operators
        self.operators = [
            '+', '-', '*', '/', '%', '++', '--', '==', '!=', '>', '<', '>=', '<=', '&&', '||', '!', '&', '|', '^',
            '~', '<<', '>>', '=', '+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '&=', '|=', '^=', '->', '.', '{', '}'
        ]
        
        # Define the C types
        self.types = [
            'int', 'char', 'float', 'double', 'void', 'short', 'long', 'signed', 'unsigned', 'const'
        ]
        
        # Define the C preprocessor directives
        self.directives = [
            '#include', '#define', '#ifndef', '#ifdef', '#endif', '#undef', '#if', '#elif', '#else', '#error', '#pragma'
        ]
        
        # Define the text formats for syntax highlighting
        self.keywordFormat = QTextCharFormat()
        self.keywordFormat.setForeground(QColor(64, 128, 255))
        self.keywordFormat.setFontWeight(QFont.Bold)
        
        self.operatorFormat = QTextCharFormat()
        self.operatorFormat.setForeground(QColor(0, 0, 255))
        
        self.typeFormat = QTextCharFormat()
        self.typeFormat.setForeground(QColor(0, 128, 0))
        self.typeFormat.setFontWeight(QFont.Bold)
        
        self.directiveFormat = QTextCharFormat()
        self.directiveFormat.setForeground(QColor(128, 0, 128))
        
        self.stringFormat = QTextCharFormat()
        self.stringFormat.setForeground(QColor(255, 0, 0))
        
        self.commentFormat = QTextCharFormat()
        self.commentFormat.setForeground(QColor(128, 128, 128))
        
        # Define the regular expressions for syntax highlighting
        self.rules = []
        
        # C keywords
        keywordPattern = '\\b(' + '|'.join(self.keywords) + ')\\b'
        self.rules.append((QRegExp(keywordPattern), self.keywordFormat))
        
        # C operators
        operatorPattern = '|'.join([QRegExp.escape(op) for op in self.operators])
        self.rules.append((QRegExp(operatorPattern), self.operatorFormat))
        
        # C types
        typePattern = '\\b(' + '|'.join(self.types) + ')\\b'
        self.rules.append((QRegExp(typePattern), self.typeFormat))
        
        # C preprocessor directives
        directivePattern = '\\b(' + '|'.join(self.directives) + ')\\b'
        self.rules.append((QRegExp(directivePattern), self.directiveFormat))
        
        # String literals
        self.rules.append((QRegExp('".*?"'), self.stringFormat))
        self.rules.append((QRegExp('\'.*?\''), self.stringFormat))
        
        # Single-line comments
        self.rules.append((QRegExp('//[^\n]*'), self.commentFormat))
        
        # Multi-line comments
        self.rules.append((QRegExp('/\\*'), self.commentFormat))
        self.rules.append((QRegExp('\\*/'), self.commentFormat))

        self.highlight_lines = dict()

    def highlightBlock(self, text):
        for pattern, format in self.rules:
            expression = QRegExp(pattern)
            index = expression.indexIn(text)
            while index >= 0:
                length = expression.matchedLength()
                self.setFormat(index, length, format)
                index = expression.indexIn(text, index + length)

        line = self.currentBlock().blockNumber()
        fmt = self.highlight_lines.get(line)
        if fmt is not None:
            self.setFormat(0, len(text), fmt)

    def highlight_line(self, line, fmt):
        if isinstance(line, int) and line >= 0 and isinstance(fmt, QTextCharFormat):
            self.highlight_lines[line] = fmt
            tb = self.document().findBlockByLineNumber(line)
            self.rehighlightBlock(tb)

    def clear_highlight(self):
        self.highlight_lines = dict()
        self.rehighlight()


class CodeEditor(QTextEdit):
    def __init__(self, parent=None):
        super(CodeEditor, self).__init__(parent)
        
        # Set the font and tab stop width
        font = QFont('Courier New')
        font.setFixedPitch(True)
        font.setPointSize(10)
        self.setFont(font)
        self.setTabStopWidth(20)
        
        # Enable line wrapping
        self.setLineWrapMode(QTextEdit.NoWrap)
        
        # Syntax highlighting
        self.highlighter = CCodeHighlighter(self.document())

if __name__ == "__main__":
    app = QApplication(sys.argv)
    mainWindow = MainWindow()
    mainWindow.show()
    app.exec()