import sys

from PyQt5.QtCore import QRegExp, QStringListModel, Qt
from PyQt5.QtGui import (QColor, QFont, QSyntaxHighlighter, QTextCharFormat,
                         QTextCursor)
from PyQt5.QtWidgets import (QApplication, QCompleter, QMainWindow,
                             QPlainTextEdit)


class CCodeHighlighter(QSyntaxHighlighter):
    def __init__(self, parent=None):
        super(CCodeHighlighter, self).__init__(parent)
        
        # Define the C keywords
        self.keywords = [
            'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 'extern',
            'float', 'for', 'goto', 'if', 'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof', 'static',
            'struct', 'switch', 'typedef', 'union', 'unsigned', 'void', 'volatile', 'while'
        ]
        
        # Define the C operators
        self.operators = [
            '+', '-', '*', '/', '%', '++', '--', '==', '!=', '>', '<', '>=', '<=', '&&', '||', '!', '&', '|', '^',
            '~', '<<', '>>', '=', '+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '&=', '|=', '^=', '->', '.'
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

    def highlightBlock(self, text):
        for pattern, format in self.rules:
            expression = QRegExp(pattern)
            index = expression.indexIn(text)
            while index >= 0:
                length = expression.matchedLength()
                self.setFormat(index, length, format)
                index = expression.indexIn(text, index + length)


class CodeEditor(QPlainTextEdit):
    def __init__(self, parent=None):
        super(CodeEditor, self).__init__(parent)
        
        # Set the font and tab stop width
        font = QFont('Courier New')
        font.setFixedPitch(True)
        font.setPointSize(10)
        self.setFont(font)
        self.setTabStopWidth(20)
        
        # Enable line wrapping
        self.setLineWrapMode(QPlainTextEdit.NoWrap)
        
        # Syntax highlighting
        self.highlighter = CCodeHighlighter(self.document())

        # Code completion
        
        self.completer = QCompleter()
        self.completer.setWidget(self)
        self.completer.setCompletionMode(QCompleter.PopupCompletion)
        self.completer.setModel(self.createCompleterModel())
        self.completer.setCaseSensitivity(Qt.CaseInsensitive)
        self.setCompleter(self.completer)

    def setCompleter(self, completer):
        self.completer = completer
        self.completer.setWidget(self)
        self.completer.setCompletionMode(QCompleter.PopupCompletion)
        self.completer.setModel(self.createCompleterModel())
        self.completer.setCaseSensitivity(Qt.CaseInsensitive)

    def completer(self):
        return self.completer

    def createCompleterModel(self):
        keywords = ['auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 'extern',
            'float', 'for', 'goto', 'if', 'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof', 'static',
            'struct', 'switch', 'typedef', 'union', 'unsigned', 'void', 'volatile', 'while']

        model = QStringListModel()
        model.setStringList(keywords)
        return model

    def textUnderCursor(self):
        cursor = self.textCursor()
        cursor.select(QTextCursor.WordUnderCursor)
        return cursor.selectedText()

    def keyPressEvent(self, event):
        if self.completer and self.completer.popup().isVisible():
            if event.key() == Qt.Key_Return or event.key() == Qt.Key_Enter:
                event.ignore()
                return
        
        super(CodeEditor, self).keyPressEvent(event)
        
        if event.key() == Qt.Key_Tab:
            completionPrefix = self.textUnderCursor()
            if completionPrefix != "":
                self.completer.setCompletionPrefix(completionPrefix)
                self.completer.popup().setCurrentIndex(
                    self.completer.completionModel().index(0, 0)
                )
                rect = self.cursorRect()
                rect.setWidth(self.completer.popup().sizeHintForColumn(0)
                              + self.completer.popup().verticalScrollBar().sizeHint().width())
                self.completer.complete(rect)


if __name__ == '__main__':
    app = QApplication(sys.argv)

    # Create a QMainWindow
    window = QMainWindow()
    
    # Create a CodeEditor widget and set it as the central widget of the main window
    code_editor = CodeEditor()
    window.setCentralWidget(code_editor)
    
    # Set window properties
    window.setWindowTitle('Code Editor')
    window.setGeometry(100, 100, 800, 600)
    
    # Show the main window
    window.show()

    sys.exit(app.exec_())
