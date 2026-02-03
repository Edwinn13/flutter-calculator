import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // What the user is building (accumulator)
  String _expression = '';
  // Last evaluated result (shown after =)
  String _result = '';

  // Prevents weird input like "++" or starting with "*"
  bool get _hasNumberAtEnd =>
      _expression.isNotEmpty && RegExp(r'[0-9)]$').hasMatch(_expression);

  bool get _hasOperatorAtEnd =>
      _expression.isNotEmpty && RegExp(r'[\+\-\*\/]$').hasMatch(_expression);

  void _clear() {
    setState(() {
      _expression = '';
      _result = '';
    });
  }

  void _appendDigit(String digit) {
    setState(() {
      // If last action was "=", and they start typing, start a new expression
      if (_result.isNotEmpty && _expression.contains('=')) {
        _expression = '';
        _result = '';
      }
      _expression += digit;
    });
  }

  void _appendDot() {
    // Prevent multiple dots in the same number chunk
    final lastNumberChunk = _expression.split(RegExp(r'[\+\-\*\/]')).last;
    if (lastNumberChunk.contains('.')) return;

    setState(() {
      if (_expression.isEmpty || _hasOperatorAtEnd) {
        _expression += '0.';
      } else {
        _expression += '.';
      }
    });
  }

  void _appendOperator(String op) {
    setState(() {
      // If user just evaluated, allow continuing from result
      if (_expression.contains('=') && _result.isNotEmpty) {
        _expression = _result; // continue calculation from last result
        _result = '';
      }

      if (_expression.isEmpty) {
        // allow starting with negative sign
        if (op == '-') _expression = '-';
        return;
      }

      if (_hasOperatorAtEnd) {
        // replace the last operator (e.g. "5 + " then press "*" -> "5 * ")
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else if (_hasNumberAtEnd || _expression.endsWith(')')) {
        _expression += op;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_expression.isEmpty) return;
      _expression = _expression.substring(0, _expression.length - 1);
    });
  }

  String _pretty(String expr) {
    // Optional: add spaces around operators for nicer display
    return expr.replaceAllMapped(RegExp(r'[\+\-\*\/]'), (m) => ' ${m[0]} ');
  }

  void _evaluate() {
    if (_expression.isEmpty) return;
    if (_hasOperatorAtEnd) return; // don't evaluate "5+"

    try {
      // Replace display operators with parser-friendly ones (we use * and / already)
      final parseMe = _expression;

      final expressionAst = Expression.parse(parseMe);
      final evaluator = const ExpressionEvaluator();

      final dynamic raw = evaluator.eval(expressionAst, {});

      // Handle non-finite numbers (division by zero etc.)
      final num value = (raw is num) ? raw : num.parse(raw.toString());
      if (value.isNaN || value.isInfinite) {
        throw const FormatException('Math error');
      }

      // Format: if it's an int, display as int. Otherwise 6 dp trimmed.
      String formatted;
      if (value % 1 == 0) {
        formatted = value.toInt().toString();
      } else {
        formatted = value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      }

      setState(() {
        // accumulator example: "2 + 3 * 4 = 14"
        _result = formatted;
        _expression = '${_expression}=${_result}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
        _expression = '${_expression}=Error';
      });

      // Also show a snackbar (nice UX)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid expression / math error')),
      );
    }
  }

  Widget _btn(
    String text, {
    Color? bg,
    Color? fg,
    VoidCallback? onTap,
    bool wide = false,
  }) {
    return Expanded(
      flex: wide ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          onPressed: onTap,
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    // Display string: show expression with spaces, or 0
    final displayText =
        _expression.isEmpty ? '0' : _pretty(_expression.replaceAll('=', ' = '));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edwin Ortiz Matos'),
        backgroundColor: color.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayText,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result.isEmpty ? '' : _result,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      _btn('C',
                          bg: Colors.red.shade600,
                          fg: Colors.white,
                          onTap: _clear),
                      _btn('⌫',
                          bg: Colors.blueGrey.shade200,
                          fg: Colors.black,
                          onTap: _backspace),
                      _btn('/',
                          bg: Colors.orange.shade600,
                          fg: Colors.white,
                          onTap: () => _appendOperator('/')),
                      _btn('*',
                          bg: Colors.orange.shade600,
                          fg: Colors.white,
                          onTap: () => _appendOperator('*')),
                    ],
                  ),
                  Row(
                    children: [
                      _btn('7', onTap: () => _appendDigit('7')),
                      _btn('8', onTap: () => _appendDigit('8')),
                      _btn('9', onTap: () => _appendDigit('9')),
                      _btn('-',
                          bg: Colors.orange.shade600,
                          fg: Colors.white,
                          onTap: () => _appendOperator('-')),
                    ],
                  ),
                  Row(
                    children: [
                      _btn('4', onTap: () => _appendDigit('4')),
                      _btn('5', onTap: () => _appendDigit('5')),
                      _btn('6', onTap: () => _appendDigit('6')),
                      _btn('+',
                          bg: Colors.orange.shade600,
                          fg: Colors.white,
                          onTap: () => _appendOperator('+')),
                    ],
                  ),
                  Row(
                    children: [
                      _btn('1', onTap: () => _appendDigit('1')),
                      _btn('2', onTap: () => _appendDigit('2')),
                      _btn('3', onTap: () => _appendDigit('3')),
                      _btn('=',
                          bg: Colors.green.shade700,
                          fg: Colors.white,
                          onTap: _evaluate),
                    ],
                  ),
                  Row(
                    children: [
                      _btn('0', wide: true, onTap: () => _appendDigit('0')),
                      _btn('.', onTap: _appendDot),
                      _btn('=',
                          bg: Colors.green.shade700,
                          fg: Colors.white,
                          onTap: _evaluate),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
