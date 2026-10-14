@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpSlotTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        #expect(item.status == Referrals.WeightedFollowUpSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        try item.moveTo(Referrals.WeightedFollowUpSlotStatus.validated)
        #expect(item.status == Referrals.WeightedFollowUpSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        item.status = Referrals.WeightedFollowUpSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedFollowUpSlotStatus.created) }
    }
}
