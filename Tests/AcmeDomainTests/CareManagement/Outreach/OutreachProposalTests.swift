@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachProposalTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newOutreachProposal("code-647", name: "name-387")
        #expect(item.status == CareManagement.OutreachProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newOutreachProposal("code-647", name: "name-387")
        try item.moveTo(CareManagement.OutreachProposalStatus.resolved)
        #expect(item.status == CareManagement.OutreachProposalStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newOutreachProposal("code-647", name: "name-387")
        item.status = CareManagement.OutreachProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachProposalStatus.`open`) }
    }
}
