@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelPlanTests {
    @Test func startsInDraft() throws {
        let item = Labs.newTieredPanelPlan("code-319", title: "title-874")
        #expect(item.status == Labs.TieredPanelPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newTieredPanelPlan("code-319", title: "title-874")
        try item.moveTo(Labs.TieredPanelPlanStatus.suspended)
        #expect(item.status == Labs.TieredPanelPlanStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newTieredPanelPlan("code-319", title: "title-874")
        item.status = Labs.TieredPanelPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredPanelPlanStatus.draft) }
    }
}
