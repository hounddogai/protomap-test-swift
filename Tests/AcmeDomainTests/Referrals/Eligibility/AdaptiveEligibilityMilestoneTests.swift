@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveEligibilityMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newAdaptiveEligibilityMilestone("code-270", title: "title-143")
        #expect(item.status == Referrals.AdaptiveEligibilityMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newAdaptiveEligibilityMilestone("code-270", title: "title-143")
        try item.moveTo(Referrals.AdaptiveEligibilityMilestoneStatus.archived)
        #expect(item.status == Referrals.AdaptiveEligibilityMilestoneStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newAdaptiveEligibilityMilestone("code-270", title: "title-143")
        item.status = Referrals.AdaptiveEligibilityMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveEligibilityMilestoneStatus.`open`) }
    }
}
