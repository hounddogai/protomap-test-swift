@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkProposalTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newBatchedNetworkProposal("code-585", name: "name-704")
        #expect(item.status == Referrals.BatchedNetworkProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newBatchedNetworkProposal("code-585", name: "name-704")
        try item.moveTo(Referrals.BatchedNetworkProposalStatus.resolved)
        #expect(item.status == Referrals.BatchedNetworkProposalStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newBatchedNetworkProposal("code-585", name: "name-704")
        item.status = Referrals.BatchedNetworkProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedNetworkProposalStatus.`open`) }
    }
}
