@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelBudgetTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        #expect(item.status == Labs.CappedPanelBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        try item.moveTo(Labs.CappedPanelBudgetStatus.retired)
        #expect(item.status == Labs.CappedPanelBudgetStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        item.status = Labs.CappedPanelBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedPanelBudgetStatus.created) }
    }
}
