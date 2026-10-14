@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRecordTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelRecord("code-876", label: "label-584")
        #expect(item.status == Labs.PanelRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newPanelRecord("code-876", label: "label-584")
        try item.moveTo(Labs.PanelRecordStatus.inProgress)
        #expect(item.status == Labs.PanelRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelRecord("code-876", label: "label-584")
        item.status = Labs.PanelRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelRecordStatus.planned) }
    }
}
