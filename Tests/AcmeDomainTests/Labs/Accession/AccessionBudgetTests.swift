@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBudgetTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionBudget("code-473", label: "label-330")
        #expect(item.status == Labs.AccessionBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newAccessionBudget("code-473", label: "label-330")
        try item.moveTo(Labs.AccessionBudgetStatus.pending)
        #expect(item.status == Labs.AccessionBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionBudget("code-473", label: "label-330")
        item.status = Labs.AccessionBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionBudgetStatus.draft) }
    }
}
