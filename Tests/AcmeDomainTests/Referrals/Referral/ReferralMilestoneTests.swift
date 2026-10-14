@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newReferralMilestone("code-390", name: "name-942")
        #expect(item.status == Referrals.ReferralMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newReferralMilestone("code-390", name: "name-942")
        try item.moveTo(Referrals.ReferralMilestoneStatus.completed)
        #expect(item.status == Referrals.ReferralMilestoneStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newReferralMilestone("code-390", name: "name-942")
        item.status = Referrals.ReferralMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralMilestoneStatus.planned) }
    }
}
