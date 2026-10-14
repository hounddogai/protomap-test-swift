@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelAllocationTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAdaptivePanelAllocation("code-529", title: "title-608")
        #expect(item.status == Labs.AdaptivePanelAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newAdaptivePanelAllocation("code-529", title: "title-608")
        try item.moveTo(Labs.AdaptivePanelAllocationStatus.rejected)
        #expect(item.status == Labs.AdaptivePanelAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAdaptivePanelAllocation("code-529", title: "title-608")
        item.status = Labs.AdaptivePanelAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptivePanelAllocationStatus.proposed) }
    }
}
