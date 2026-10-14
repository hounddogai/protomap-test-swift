@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProposalTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        #expect(item.status == Staffing.CredentialProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        try item.moveTo(Staffing.CredentialProposalStatus.warming)
        #expect(item.status == Staffing.CredentialProposalStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        item.status = Staffing.CredentialProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialProposalStatus.idle) }
    }
}
