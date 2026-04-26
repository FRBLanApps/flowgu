import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<UserProfile> fetchCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const UserProfile(
      name: 'Flowgu User',
      uid: '10086',
      rankName: '绿名',
      acceptedCount: 120,
      submissionCount: 340,
      ranking: 60,
      valuation: 100,
      avatarUrl: 'https://cdn.luogu.com.cn/upload/usericon/1.png',
      slogan: '让每一次刷题都有回声',
      introduction: '这里会展示公开个人简介、练习统计、动态和近期提交。',
    );
  }
}
