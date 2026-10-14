@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBudgetTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInteractionBudget("code-966", title: "title-869")
        #expect(item.status == Pharmacy.InteractionBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newInteractionBudget("code-966", title: "title-869")
        try item.moveTo(Pharmacy.InteractionBudgetStatus.warming)
        #expect(item.status == Pharmacy.InteractionBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInteractionBudget("code-966", title: "title-869")
        item.status = Pharmacy.InteractionBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionBudgetStatus.idle) }
    }
}
