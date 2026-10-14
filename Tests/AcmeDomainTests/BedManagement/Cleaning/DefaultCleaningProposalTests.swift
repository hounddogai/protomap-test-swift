@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningProposalTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDefaultCleaningProposal("code-114", name: "name-26")
        #expect(item.status == BedManagement.DefaultCleaningProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newDefaultCleaningProposal("code-114", name: "name-26")
        try item.moveTo(BedManagement.DefaultCleaningProposalStatus.revoked)
        #expect(item.status == BedManagement.DefaultCleaningProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDefaultCleaningProposal("code-114", name: "name-26")
        item.status = BedManagement.DefaultCleaningProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCleaningProposalStatus.requested) }
    }
}
