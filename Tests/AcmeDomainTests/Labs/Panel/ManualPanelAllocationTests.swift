@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualPanelAllocationTests {
    @Test func startsInOpen() throws {
        let item = Labs.newManualPanelAllocation("code-72", title: "title-685")
        #expect(item.status == Labs.ManualPanelAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newManualPanelAllocation("code-72", title: "title-685")
        try item.moveTo(Labs.ManualPanelAllocationStatus.resolved)
        #expect(item.status == Labs.ManualPanelAllocationStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newManualPanelAllocation("code-72", title: "title-685")
        item.status = Labs.ManualPanelAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualPanelAllocationStatus.`open`) }
    }
}
