import '../models/code_submission.dart';

abstract class SubmissionRepository {
  Future<CodeSubmissionResult> submit(CodeSubmissionRequest request);
}
