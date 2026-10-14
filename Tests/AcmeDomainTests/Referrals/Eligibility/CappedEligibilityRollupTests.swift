@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityRollupTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedEligibilityRollup("code-176", label: "label-680")
        #expect(item.status == Referrals.CappedEligibilityRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newCappedEligibilityRollup("code-176", label: "label-680")
        try item.moveTo(Referrals.CappedEligibilityRollupStatus.approved)
        #expect(item.status == Referrals.CappedEligibilityRollupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedEligibilityRollup("code-176", label: "label-680")
        item.status = Referrals.CappedEligibilityRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedEligibilityRollupStatus.proposed) }
    }
}
