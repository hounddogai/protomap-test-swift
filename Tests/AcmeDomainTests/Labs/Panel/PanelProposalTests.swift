@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelProposalTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelProposal("code-677", label: "label-718")
        #expect(item.status == Labs.PanelProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newPanelProposal("code-677", label: "label-718")
        try item.moveTo(Labs.PanelProposalStatus.rejected)
        #expect(item.status == Labs.PanelProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelProposal("code-677", label: "label-718")
        item.status = Labs.PanelProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelProposalStatus.proposed) }
    }
}
