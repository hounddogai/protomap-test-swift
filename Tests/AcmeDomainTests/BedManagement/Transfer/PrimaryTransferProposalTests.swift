@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferProposalTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newPrimaryTransferProposal("code-938", name: "name-396")
        #expect(item.status == BedManagement.PrimaryTransferProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newPrimaryTransferProposal("code-938", name: "name-396")
        try item.moveTo(BedManagement.PrimaryTransferProposalStatus.approved)
        #expect(item.status == BedManagement.PrimaryTransferProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newPrimaryTransferProposal("code-938", name: "name-396")
        item.status = BedManagement.PrimaryTransferProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryTransferProposalStatus.proposed) }
    }
}
