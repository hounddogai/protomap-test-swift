@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProposalTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newRollingClosureProposal("code-94", label: "label-599")
        #expect(item.status == Referrals.RollingClosureProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newRollingClosureProposal("code-94", label: "label-599")
        try item.moveTo(Referrals.RollingClosureProposalStatus.resolved)
        #expect(item.status == Referrals.RollingClosureProposalStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newRollingClosureProposal("code-94", label: "label-599")
        item.status = Referrals.RollingClosureProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingClosureProposalStatus.`open`) }
    }
}
