@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralVarianceTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newWeightedReferralVariance("code-613", name: "name-855")
        #expect(item.status == Referrals.WeightedReferralVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newWeightedReferralVariance("code-613", name: "name-855")
        try item.moveTo(Referrals.WeightedReferralVarianceStatus.approved)
        #expect(item.status == Referrals.WeightedReferralVarianceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newWeightedReferralVariance("code-613", name: "name-855")
        item.status = Referrals.WeightedReferralVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralVarianceStatus.proposed) }
    }
}
