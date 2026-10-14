@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualEligibilityProposalTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newManualEligibilityProposal("code-707", title: "title-563")
        #expect(item.status == Referrals.ManualEligibilityProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newManualEligibilityProposal("code-707", title: "title-563")
        try item.moveTo(Referrals.ManualEligibilityProposalStatus.inReview)
        #expect(item.status == Referrals.ManualEligibilityProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newManualEligibilityProposal("code-707", title: "title-563")
        item.status = Referrals.ManualEligibilityProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualEligibilityProposalStatus.`open`) }
    }
}
