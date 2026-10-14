@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelAllocation("code-627", title: "title-722")
        #expect(item.status == Labs.PanelAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newPanelAllocation("code-627", title: "title-722")
        try item.moveTo(Labs.PanelAllocationStatus.scheduled)
        #expect(item.status == Labs.PanelAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelAllocation("code-627", title: "title-722")
        item.status = Labs.PanelAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelAllocationStatus.planned) }
    }
}
