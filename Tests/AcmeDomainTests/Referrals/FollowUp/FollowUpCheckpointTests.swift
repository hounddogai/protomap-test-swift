@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpCheckpoint("code-599", title: "title-698")
        #expect(item.status == Referrals.FollowUpCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Referrals.newFollowUpCheckpoint("code-599", title: "title-698")
        try item.moveTo(Referrals.FollowUpCheckpointStatus.cancelled)
        #expect(item.status == Referrals.FollowUpCheckpointStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpCheckpoint("code-599", title: "title-698")
        item.status = Referrals.FollowUpCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpCheckpointStatus.planned) }
    }
}
