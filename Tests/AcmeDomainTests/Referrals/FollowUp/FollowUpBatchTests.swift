@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBatchTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpBatch("code-873", name: "name-245")
        #expect(item.status == Referrals.FollowUpBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newFollowUpBatch("code-873", name: "name-245")
        try item.moveTo(Referrals.FollowUpBatchStatus.inProgress)
        #expect(item.status == Referrals.FollowUpBatchStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpBatch("code-873", name: "name-245")
        item.status = Referrals.FollowUpBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpBatchStatus.planned) }
    }
}
