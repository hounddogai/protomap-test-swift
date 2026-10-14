@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionProposalTests {
    @Test func startsInRequested() throws {
        let item = Labs.newLegacyAccessionProposal("code-626", name: "name-323")
        #expect(item.status == Labs.LegacyAccessionProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newLegacyAccessionProposal("code-626", name: "name-323")
        try item.moveTo(Labs.LegacyAccessionProposalStatus.expired)
        #expect(item.status == Labs.LegacyAccessionProposalStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newLegacyAccessionProposal("code-626", name: "name-323")
        item.status = Labs.LegacyAccessionProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionProposalStatus.requested) }
    }
}
