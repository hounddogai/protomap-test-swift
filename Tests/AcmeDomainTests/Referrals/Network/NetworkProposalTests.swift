@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkProposalTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newNetworkProposal("code-673", label: "label-207")
        #expect(item.status == Referrals.NetworkProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newNetworkProposal("code-673", label: "label-207")
        try item.moveTo(Referrals.NetworkProposalStatus.validated)
        #expect(item.status == Referrals.NetworkProposalStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newNetworkProposal("code-673", label: "label-207")
        item.status = Referrals.NetworkProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkProposalStatus.created) }
    }
}
