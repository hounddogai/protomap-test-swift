@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newLegacyFollowUpCheckpoint("code-584", name: "name-673")
        #expect(item.status == Referrals.LegacyFollowUpCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newLegacyFollowUpCheckpoint("code-584", name: "name-673")
        try item.moveTo(Referrals.LegacyFollowUpCheckpointStatus.scheduled)
        #expect(item.status == Referrals.LegacyFollowUpCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newLegacyFollowUpCheckpoint("code-584", name: "name-673")
        item.status = Referrals.LegacyFollowUpCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyFollowUpCheckpointStatus.planned) }
    }
}
