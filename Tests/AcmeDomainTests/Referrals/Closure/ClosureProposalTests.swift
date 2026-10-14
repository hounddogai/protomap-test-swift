@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureProposalTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newClosureProposal("code-909", title: "title-314")
        #expect(item.status == Referrals.ClosureProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newClosureProposal("code-909", title: "title-314")
        try item.moveTo(Referrals.ClosureProposalStatus.inReview)
        #expect(item.status == Referrals.ClosureProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newClosureProposal("code-909", title: "title-314")
        item.status = Referrals.ClosureProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureProposalStatus.`open`) }
    }
}
