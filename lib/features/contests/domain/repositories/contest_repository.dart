import '../models/contest.dart';

abstract class ContestRepository {
  Future<List<Contest>> fetchOfficialContests();
  Future<List<Contest>> fetchPublicContests();
  Future<List<Contest>> fetchAtCoderContests();
  Future<Contest> fetchContestDetail(Contest contest);
}
