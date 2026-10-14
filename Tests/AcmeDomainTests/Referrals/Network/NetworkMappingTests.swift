@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkMappingTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newNetworkMapping("code-337", name: "name-847")
        #expect(item.status == Referrals.NetworkMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newNetworkMapping("code-337", name: "name-847")
        try item.moveTo(Referrals.NetworkMappingStatus.approved)
        #expect(item.status == Referrals.NetworkMappingStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newNetworkMapping("code-337", name: "name-847")
        item.status = Referrals.NetworkMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkMappingStatus.proposed) }
    }
}
