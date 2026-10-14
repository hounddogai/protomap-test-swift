@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferProposalTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDefaultTransferProposal("code-402", label: "label-118")
        #expect(item.status == BedManagement.DefaultTransferProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDefaultTransferProposal("code-402", label: "label-118")
        try item.moveTo(BedManagement.DefaultTransferProposalStatus.warming)
        #expect(item.status == BedManagement.DefaultTransferProposalStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDefaultTransferProposal("code-402", label: "label-118")
        item.status = BedManagement.DefaultTransferProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultTransferProposalStatus.idle) }
    }
}
