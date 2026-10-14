@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newBatchedInteractionBudget("code-181", title: "title-592")
        #expect(item.status == Pharmacy.BatchedInteractionBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newBatchedInteractionBudget("code-181", title: "title-592")
        try item.moveTo(Pharmacy.BatchedInteractionBudgetStatus.scheduled)
        #expect(item.status == Pharmacy.BatchedInteractionBudgetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newBatchedInteractionBudget("code-181", title: "title-592")
        item.status = Pharmacy.BatchedInteractionBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedInteractionBudgetStatus.planned) }
    }
}
