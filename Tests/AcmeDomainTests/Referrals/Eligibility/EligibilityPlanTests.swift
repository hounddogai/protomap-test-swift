@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPlanTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityPlan("code-673", title: "title-637")
        #expect(item.status == Referrals.EligibilityPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newEligibilityPlan("code-673", title: "title-637")
        try item.moveTo(Referrals.EligibilityPlanStatus.scheduled)
        #expect(item.status == Referrals.EligibilityPlanStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityPlan("code-673", title: "title-637")
        item.status = Referrals.EligibilityPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityPlanStatus.planned) }
    }
}
