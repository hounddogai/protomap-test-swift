@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProposalTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newReferralProposal("code-516", title: "title-154")
        #expect(item.status == Referrals.ReferralProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newReferralProposal("code-516", title: "title-154")
        try item.moveTo(Referrals.ReferralProposalStatus.suspended)
        #expect(item.status == Referrals.ReferralProposalStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newReferralProposal("code-516", title: "title-154")
        item.status = Referrals.ReferralProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralProposalStatus.draft) }
    }
}
