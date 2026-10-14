@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProposalTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultProposal("code-870", label: "label-867")
        #expect(item.status == Labs.ResultProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newResultProposal("code-870", label: "label-867")
        try item.moveTo(Labs.ResultProposalStatus.granted)
        #expect(item.status == Labs.ResultProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultProposal("code-870", label: "label-867")
        item.status = Labs.ResultProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultProposalStatus.requested) }
    }
}
