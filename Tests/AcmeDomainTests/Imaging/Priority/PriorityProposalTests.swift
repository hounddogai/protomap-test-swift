@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityProposalTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPriorityProposal("code-970", name: "name-562")
        #expect(item.status == Imaging.PriorityProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newPriorityProposal("code-970", name: "name-562")
        try item.moveTo(Imaging.PriorityProposalStatus.granted)
        #expect(item.status == Imaging.PriorityProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPriorityProposal("code-970", name: "name-562")
        item.status = Imaging.PriorityProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityProposalStatus.requested) }
    }
}
