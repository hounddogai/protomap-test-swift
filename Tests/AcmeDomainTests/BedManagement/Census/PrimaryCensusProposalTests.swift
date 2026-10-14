@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusProposalTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newPrimaryCensusProposal("code-651", title: "title-904")
        #expect(item.status == BedManagement.PrimaryCensusProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newPrimaryCensusProposal("code-651", title: "title-904")
        try item.moveTo(BedManagement.PrimaryCensusProposalStatus.queued)
        #expect(item.status == BedManagement.PrimaryCensusProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newPrimaryCensusProposal("code-651", title: "title-904")
        item.status = BedManagement.PrimaryCensusProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCensusProposalStatus.new) }
    }
}
