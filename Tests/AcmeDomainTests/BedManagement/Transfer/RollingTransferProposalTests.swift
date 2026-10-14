@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferProposalTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRollingTransferProposal("code-379", title: "title-539")
        #expect(item.status == BedManagement.RollingTransferProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newRollingTransferProposal("code-379", title: "title-539")
        try item.moveTo(BedManagement.RollingTransferProposalStatus.inReview)
        #expect(item.status == BedManagement.RollingTransferProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRollingTransferProposal("code-379", title: "title-539")
        item.status = BedManagement.RollingTransferProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingTransferProposalStatus.`open`) }
    }
}
