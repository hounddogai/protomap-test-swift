@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityScoreTests {
    @Test func startsInNew() throws {
        let item = Referrals.newBatchedEligibilityScore("code-401", title: "title-206")
        #expect(item.status == Referrals.BatchedEligibilityScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newBatchedEligibilityScore("code-401", title: "title-206")
        try item.moveTo(Referrals.BatchedEligibilityScoreStatus.failed)
        #expect(item.status == Referrals.BatchedEligibilityScoreStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newBatchedEligibilityScore("code-401", title: "title-206")
        item.status = Referrals.BatchedEligibilityScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedEligibilityScoreStatus.new) }
    }
}
