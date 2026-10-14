@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralAuditTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newWeightedReferralAudit("code-592", name: "name-93")
        #expect(item.status == Referrals.WeightedReferralAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newWeightedReferralAudit("code-592", name: "name-93")
        try item.moveTo(Referrals.WeightedReferralAuditStatus.approved)
        #expect(item.status == Referrals.WeightedReferralAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newWeightedReferralAudit("code-592", name: "name-93")
        item.status = Referrals.WeightedReferralAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralAuditStatus.proposed) }
    }
}
