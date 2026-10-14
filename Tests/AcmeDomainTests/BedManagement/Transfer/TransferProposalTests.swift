@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferProposalTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTransferProposal("code-402", label: "label-94")
        #expect(item.status == BedManagement.TransferProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newTransferProposal("code-402", label: "label-94")
        try item.moveTo(BedManagement.TransferProposalStatus.granted)
        #expect(item.status == BedManagement.TransferProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTransferProposal("code-402", label: "label-94")
        item.status = BedManagement.TransferProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferProposalStatus.requested) }
    }
}
