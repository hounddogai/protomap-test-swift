@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityMilestone("code-224", name: "name-370")
        #expect(item.status == Referrals.EligibilityMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newEligibilityMilestone("code-224", name: "name-370")
        try item.moveTo(Referrals.EligibilityMilestoneStatus.suspended)
        #expect(item.status == Referrals.EligibilityMilestoneStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityMilestone("code-224", name: "name-370")
        item.status = Referrals.EligibilityMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityMilestoneStatus.draft) }
    }
}
