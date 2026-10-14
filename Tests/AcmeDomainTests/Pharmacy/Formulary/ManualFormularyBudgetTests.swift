@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualFormularyBudgetTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newManualFormularyBudget("code-78", title: "title-103")
        #expect(item.status == Pharmacy.ManualFormularyBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newManualFormularyBudget("code-78", title: "title-103")
        try item.moveTo(Pharmacy.ManualFormularyBudgetStatus.running)
        #expect(item.status == Pharmacy.ManualFormularyBudgetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newManualFormularyBudget("code-78", title: "title-103")
        item.status = Pharmacy.ManualFormularyBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualFormularyBudgetStatus.new) }
    }
}
