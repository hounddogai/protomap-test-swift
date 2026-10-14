@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPlanTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingPanelPlan("code-467", label: "label-974")
        #expect(item.status == Labs.RollingPanelPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newRollingPanelPlan("code-467", label: "label-974")
        try item.moveTo(Labs.RollingPanelPlanStatus.pending)
        #expect(item.status == Labs.RollingPanelPlanStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingPanelPlan("code-467", label: "label-974")
        item.status = Labs.RollingPanelPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingPanelPlanStatus.draft) }
    }
}
