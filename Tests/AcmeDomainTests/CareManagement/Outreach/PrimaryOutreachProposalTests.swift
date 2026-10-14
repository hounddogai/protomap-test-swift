@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachProposalTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPrimaryOutreachProposal("code-106", name: "name-296")
        #expect(item.status == CareManagement.PrimaryOutreachProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newPrimaryOutreachProposal("code-106", name: "name-296")
        try item.moveTo(CareManagement.PrimaryOutreachProposalStatus.revoked)
        #expect(item.status == CareManagement.PrimaryOutreachProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPrimaryOutreachProposal("code-106", name: "name-296")
        item.status = CareManagement.PrimaryOutreachProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryOutreachProposalStatus.requested) }
    }
}
