@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedEligibilityWindowTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newWeightedEligibilityWindow("code-308", label: "label-742")
        #expect(item.status == Referrals.WeightedEligibilityWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newWeightedEligibilityWindow("code-308", label: "label-742")
        try item.moveTo(Referrals.WeightedEligibilityWindowStatus.approved)
        #expect(item.status == Referrals.WeightedEligibilityWindowStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newWeightedEligibilityWindow("code-308", label: "label-742")
        item.status = Referrals.WeightedEligibilityWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedEligibilityWindowStatus.proposed) }
    }
}
