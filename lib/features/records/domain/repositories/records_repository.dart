import '../models/submission_record.dart';

abstract class RecordsRepository {
  Future<List<SubmissionRecord>> fetchRecords();
  Future<SubmissionRecord> fetchRecordDetail(String recordId);
}
