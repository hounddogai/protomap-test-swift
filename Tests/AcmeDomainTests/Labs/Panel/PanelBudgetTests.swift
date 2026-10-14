@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBudgetTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        #expect(item.status == Labs.PanelBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        try item.moveTo(Labs.PanelBudgetStatus.rejected)
        #expect(item.status == Labs.PanelBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        item.status = Labs.PanelBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelBudgetStatus.proposed) }
    }
}
