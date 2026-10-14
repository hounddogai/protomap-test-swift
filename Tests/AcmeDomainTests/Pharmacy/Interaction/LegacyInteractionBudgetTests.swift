@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionBudgetTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newLegacyInteractionBudget("code-58", name: "name-755")
        #expect(item.status == Pharmacy.LegacyInteractionBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newLegacyInteractionBudget("code-58", name: "name-755")
        try item.moveTo(Pharmacy.LegacyInteractionBudgetStatus.pending)
        #expect(item.status == Pharmacy.LegacyInteractionBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newLegacyInteractionBudget("code-58", name: "name-755")
        item.status = Pharmacy.LegacyInteractionBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionBudgetStatus.draft) }
    }
}
