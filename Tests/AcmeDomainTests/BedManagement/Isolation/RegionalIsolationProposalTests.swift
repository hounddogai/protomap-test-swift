@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationProposalTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newRegionalIsolationProposal("code-628", title: "title-511")
        #expect(item.status == BedManagement.RegionalIsolationProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newRegionalIsolationProposal("code-628", title: "title-511")
        try item.moveTo(BedManagement.RegionalIsolationProposalStatus.pending)
        #expect(item.status == BedManagement.RegionalIsolationProposalStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newRegionalIsolationProposal("code-628", title: "title-511")
        item.status = BedManagement.RegionalIsolationProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalIsolationProposalStatus.draft) }
    }
}
