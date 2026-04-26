import '../domain/models/submission_record.dart';
import '../domain/repositories/records_repository.dart';

class MockRecordsRepository implements RecordsRepository {
  const MockRecordsRepository();

  @override
  Future<List<SubmissionRecord>> fetchRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return List.generate(20, (index) {
      final result =
          SubmissionResult.values[index % SubmissionResult.values.length];

      return SubmissionRecord(
        id: 'record-$index',
        problemId: 'P${1000 + index}',
        problemTitle: 'A+B Problem',
        userName: 'User_${index * 99}',
        language: index.isEven ? 'C++14' : 'Python 3',
        duration: '${14 + index}ms',
        memory: '${800 + index * 20}KB',
        submittedAt: index < 3 ? '刚刚' : '${index + 1} 分钟前',
        result: result,
      );
    });
  }

  @override
  Future<SubmissionRecord> fetchRecordDetail(String recordId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return SubmissionRecord(
      id: recordId,
      problemId: 'P1001',
      problemTitle: 'A+B Problem',
      userName: 'MockUser',
      language: 'C++17',
      duration: '15ms',
      memory: '812KB',
      submittedAt: '刚刚',
      result: SubmissionResult.accepted,
      score: 100,
      sourceCode:
          '#include <bits/stdc++.h>\nusing namespace std;\nint main(){return 0;}\n',
      subtasks: const [
        SubmissionSubtask(
          id: 1,
          score: 100,
          status: SubmissionResult.accepted,
          time: 15,
          memory: 812,
          testCases: [
            SubmissionTestCase(
              id: 1,
              status: SubmissionResult.accepted,
              time: 15,
              memory: 812,
              score: 100,
            ),
          ],
        ),
      ],
    );
  }
}
