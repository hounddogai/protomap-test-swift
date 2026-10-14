@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBatchTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelBatch("code-235", label: "label-929")
        #expect(item.status == Labs.PanelBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newPanelBatch("code-235", label: "label-929")
        try item.moveTo(Labs.PanelBatchStatus.rejected)
        #expect(item.status == Labs.PanelBatchStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelBatch("code-235", label: "label-929")
        item.status = Labs.PanelBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelBatchStatus.proposed) }
    }
}
