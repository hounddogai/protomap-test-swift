@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralProposalTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newWeightedReferralProposal("code-333", label: "label-942")
        #expect(item.status == Referrals.WeightedReferralProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newWeightedReferralProposal("code-333", label: "label-942")
        try item.moveTo(Referrals.WeightedReferralProposalStatus.approved)
        #expect(item.status == Referrals.WeightedReferralProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newWeightedReferralProposal("code-333", label: "label-942")
        item.status = Referrals.WeightedReferralProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralProposalStatus.proposed) }
    }
}
