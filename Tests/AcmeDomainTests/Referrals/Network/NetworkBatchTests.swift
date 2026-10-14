@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkBatchTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newNetworkBatch("code-552", label: "label-781")
        #expect(item.status == Referrals.NetworkBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newNetworkBatch("code-552", label: "label-781")
        try item.moveTo(Referrals.NetworkBatchStatus.resolved)
        #expect(item.status == Referrals.NetworkBatchStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newNetworkBatch("code-552", label: "label-781")
        item.status = Referrals.NetworkBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkBatchStatus.`open`) }
    }
}
