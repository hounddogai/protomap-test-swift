@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityQuotaTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newEligibilityQuota("code-390", label: "label-417")
        #expect(item.status == Referrals.EligibilityQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newEligibilityQuota("code-390", label: "label-417")
        try item.moveTo(Referrals.EligibilityQuotaStatus.approved)
        #expect(item.status == Referrals.EligibilityQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newEligibilityQuota("code-390", label: "label-417")
        item.status = Referrals.EligibilityQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityQuotaStatus.proposed) }
    }
}
