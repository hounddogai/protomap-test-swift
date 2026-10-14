@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInteractionBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newGlobalInteractionBudget("code-49", name: "name-881")
        #expect(item.status == Pharmacy.GlobalInteractionBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newGlobalInteractionBudget("code-49", name: "name-881")
        try item.moveTo(Pharmacy.GlobalInteractionBudgetStatus.completed)
        #expect(item.status == Pharmacy.GlobalInteractionBudgetStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newGlobalInteractionBudget("code-49", name: "name-881")
        item.status = Pharmacy.GlobalInteractionBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalInteractionBudgetStatus.planned) }
    }
}
