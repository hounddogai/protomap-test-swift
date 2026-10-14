@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBudgetTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseBudget("code-220", name: "name-56")
        #expect(item.status == Pharmacy.DispenseBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newDispenseBudget("code-220", name: "name-56")
        try item.moveTo(Pharmacy.DispenseBudgetStatus.pending)
        #expect(item.status == Pharmacy.DispenseBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseBudget("code-220", name: "name-56")
        item.status = Pharmacy.DispenseBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseBudgetStatus.draft) }
    }
}
