@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPrimarySlotBudget("code-988", title: "title-11")
        #expect(item.status == Referrals.PrimarySlotBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newPrimarySlotBudget("code-988", title: "title-11")
        try item.moveTo(Referrals.PrimarySlotBudgetStatus.inProgress)
        #expect(item.status == Referrals.PrimarySlotBudgetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPrimarySlotBudget("code-988", title: "title-11")
        item.status = Referrals.PrimarySlotBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimarySlotBudgetStatus.planned) }
    }
}
