@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyEligibilityBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newLegacyEligibilityBudget("code-129", label: "label-930")
        #expect(item.status == Referrals.LegacyEligibilityBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newLegacyEligibilityBudget("code-129", label: "label-930")
        try item.moveTo(Referrals.LegacyEligibilityBudgetStatus.inProgress)
        #expect(item.status == Referrals.LegacyEligibilityBudgetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newLegacyEligibilityBudget("code-129", label: "label-930")
        item.status = Referrals.LegacyEligibilityBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyEligibilityBudgetStatus.planned) }
    }
}
