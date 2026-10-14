@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityVarianceTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newBatchedEligibilityVariance("code-17", name: "name-985")
        #expect(item.status == Referrals.BatchedEligibilityVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newBatchedEligibilityVariance("code-17", name: "name-985")
        try item.moveTo(Referrals.BatchedEligibilityVarianceStatus.published)
        #expect(item.status == Referrals.BatchedEligibilityVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newBatchedEligibilityVariance("code-17", name: "name-985")
        item.status = Referrals.BatchedEligibilityVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedEligibilityVarianceStatus.created) }
    }
}
