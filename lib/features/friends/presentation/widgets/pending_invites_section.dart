import 'package:flutter/material.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'package:wish_nesita/features/friends/presentation/widgets/friend_request_card.dart';

class PendingInvitesSection extends StatelessWidget {
  final List<FriendRequest> requests;

  const PendingInvitesSection({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Convites pendentes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return FriendRequestCard(request: requests[index]);
          },
        ),
      ],
    );
  }
}
