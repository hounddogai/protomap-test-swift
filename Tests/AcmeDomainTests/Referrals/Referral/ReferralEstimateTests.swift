@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralEstimateTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newReferralEstimate("code-181", name: "name-719")
        #expect(item.status == Referrals.ReferralEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newReferralEstimate("code-181", name: "name-719")
        try item.moveTo(Referrals.ReferralEstimateStatus.suspended)
        #expect(item.status == Referrals.ReferralEstimateStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newReferralEstimate("code-181", name: "name-719")
        item.status = Referrals.ReferralEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralEstimateStatus.draft) }
    }
}
