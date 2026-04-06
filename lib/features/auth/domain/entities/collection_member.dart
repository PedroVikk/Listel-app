enum MemberRole { owner, member }

class CollectionMember {
  final String userId;
  final String collectionId;
  final MemberRole role;
  final String displayName;

  const CollectionMember({
    required this.userId,
    required this.collectionId,
    required this.role,
    required this.displayName,
  });
}
