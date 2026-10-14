@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProposalTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newEligibilityProposal("code-408", label: "label-117")
        #expect(item.status == Referrals.EligibilityProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newEligibilityProposal("code-408", label: "label-117")
        try item.moveTo(Referrals.EligibilityProposalStatus.published)
        #expect(item.status == Referrals.EligibilityProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newEligibilityProposal("code-408", label: "label-117")
        item.status = Referrals.EligibilityProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityProposalStatus.created) }
    }
}
