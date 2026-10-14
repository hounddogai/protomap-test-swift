@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardProposalTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newScheduledBedBoardProposal("code-99", label: "label-989")
        #expect(item.status == BedManagement.ScheduledBedBoardProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newScheduledBedBoardProposal("code-99", label: "label-989")
        try item.moveTo(BedManagement.ScheduledBedBoardProposalStatus.validated)
        #expect(item.status == BedManagement.ScheduledBedBoardProposalStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newScheduledBedBoardProposal("code-99", label: "label-989")
        item.status = BedManagement.ScheduledBedBoardProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledBedBoardProposalStatus.created) }
    }
}
