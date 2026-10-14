@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenProposalTests {
    @Test func startsInProposed() throws {
        let item = Labs.newRollingSpecimenProposal("code-595", name: "name-678")
        #expect(item.status == Labs.RollingSpecimenProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newRollingSpecimenProposal("code-595", name: "name-678")
        try item.moveTo(Labs.RollingSpecimenProposalStatus.rejected)
        #expect(item.status == Labs.RollingSpecimenProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newRollingSpecimenProposal("code-595", name: "name-678")
        item.status = Labs.RollingSpecimenProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingSpecimenProposalStatus.proposed) }
    }
}
