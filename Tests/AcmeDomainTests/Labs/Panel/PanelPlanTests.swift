@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPlanTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        #expect(item.status == Labs.PanelPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        try item.moveTo(Labs.PanelPlanStatus.pending)
        #expect(item.status == Labs.PanelPlanStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        item.status = Labs.PanelPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelPlanStatus.draft) }
    }
}
