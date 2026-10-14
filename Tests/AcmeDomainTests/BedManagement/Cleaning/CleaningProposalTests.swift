@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProposalTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newCleaningProposal("code-590", label: "label-14")
        #expect(item.status == BedManagement.CleaningProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newCleaningProposal("code-590", label: "label-14")
        try item.moveTo(BedManagement.CleaningProposalStatus.validated)
        #expect(item.status == BedManagement.CleaningProposalStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newCleaningProposal("code-590", label: "label-14")
        item.status = BedManagement.CleaningProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningProposalStatus.created) }
    }
}
