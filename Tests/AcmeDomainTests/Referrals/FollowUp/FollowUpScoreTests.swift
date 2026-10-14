@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScoreTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpScore("code-740", label: "label-604")
        #expect(item.status == Referrals.FollowUpScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newFollowUpScore("code-740", label: "label-604")
        try item.moveTo(Referrals.FollowUpScoreStatus.inProgress)
        #expect(item.status == Referrals.FollowUpScoreStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpScore("code-740", label: "label-604")
        item.status = Referrals.FollowUpScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpScoreStatus.planned) }
    }
}
