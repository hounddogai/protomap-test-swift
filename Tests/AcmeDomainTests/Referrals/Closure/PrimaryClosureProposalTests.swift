@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureProposalTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newPrimaryClosureProposal("code-677", label: "label-380")
        #expect(item.status == Referrals.PrimaryClosureProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newPrimaryClosureProposal("code-677", label: "label-380")
        try item.moveTo(Referrals.PrimaryClosureProposalStatus.published)
        #expect(item.status == Referrals.PrimaryClosureProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newPrimaryClosureProposal("code-677", label: "label-380")
        item.status = Referrals.PrimaryClosureProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryClosureProposalStatus.created) }
    }
}
