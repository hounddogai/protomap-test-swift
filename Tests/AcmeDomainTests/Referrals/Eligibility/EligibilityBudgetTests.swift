@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityBudget("code-631", name: "name-381")
        #expect(item.status == Referrals.EligibilityBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newEligibilityBudget("code-631", name: "name-381")
        try item.moveTo(Referrals.EligibilityBudgetStatus.inProgress)
        #expect(item.status == Referrals.EligibilityBudgetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityBudget("code-631", name: "name-381")
        item.status = Referrals.EligibilityBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityBudgetStatus.planned) }
    }
}
