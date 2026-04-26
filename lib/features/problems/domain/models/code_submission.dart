import 'problem.dart';

class SubmitLanguage {
  const SubmitLanguage({
    required this.id,
    required this.name,
    required this.template,
    this.type = '',
    this.highlightMode = 'text',
    this.canO2 = false,
  });

  final int id;
  final String name;
  final String template;
  final String type;
  final String highlightMode;
  final bool canO2;
}

class CodeSubmissionRequest {
  const CodeSubmissionRequest({
    required this.problem,
    required this.language,
    required this.code,
    this.enableO2 = false,
    this.captcha,
    this.contestId,
  });

  final Problem problem;
  final SubmitLanguage language;
  final String code;
  final bool enableO2;
  final String? captcha;
  final String? contestId;
}

class CodeSubmissionResult {
  const CodeSubmissionResult({
    required this.success,
    required this.message,
    this.recordId,
  });

  final bool success;
  final String message;
  final String? recordId;
}

class SubmitLanguages {
  const SubmitLanguages._();

  static const cpp17 = SubmitLanguage(
    id: 12,
    name: 'C++17',
    type: 'Cpp17',
    highlightMode: 'cpp',
    canO2: true,
    template:
        '#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n    ios::sync_with_stdio(false);\n    cin.tie(nullptr);\n\n    return 0;\n}\n',
  );

  static const values = [
    cpp17,
    SubmitLanguage(
      id: 11,
      name: 'C++14',
      type: 'Cpp14',
      highlightMode: 'cpp',
      canO2: true,
      template:
          '#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n    return 0;\n}\n',
    ),
    SubmitLanguage(
      id: 7,
      name: 'Python 3',
      type: 'Python3',
      highlightMode: 'python',
      template:
          'import sys\n\n\ndef main():\n    pass\n\n\nif __name__ == "__main__":\n    main()\n',
    ),
    SubmitLanguage(
      id: 8,
      name: 'Java 8',
      type: 'Java8',
      highlightMode: 'java',
      template:
          'import java.io.*;\nimport java.util.*;\n\npublic class Main {\n    public static void main(String[] args) throws Exception {\n    }\n}\n',
    ),
    SubmitLanguage(
      id: 46,
      name: 'Rust',
      type: 'Rust',
      highlightMode: 'rust',
      template: 'fn main() {\n}\n',
    ),
    SubmitLanguage(
      id: 52,
      name: 'Go',
      type: 'Go',
      highlightMode: 'go',
      template: 'package main\n\nfunc main() {\n}\n',
    ),
  ];

  static SubmitLanguage fallbackById(int id) {
    for (final language in values) {
      if (language.id == id) {
        return language;
      }
    }

    return SubmitLanguage(
      id: id,
      name: '语言 $id',
      template: '',
    );
  }
}
