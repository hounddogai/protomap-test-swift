@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newStrictFollowUpAdjustment("code-820", label: "label-705")
        #expect(item.status == Referrals.StrictFollowUpAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newStrictFollowUpAdjustment("code-820", label: "label-705")
        try item.moveTo(Referrals.StrictFollowUpAdjustmentStatus.inProgress)
        #expect(item.status == Referrals.StrictFollowUpAdjustmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newStrictFollowUpAdjustment("code-820", label: "label-705")
        item.status = Referrals.StrictFollowUpAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictFollowUpAdjustmentStatus.planned) }
    }
}
