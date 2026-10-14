@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkDigestTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        #expect(item.status == Referrals.TieredNetworkDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        try item.moveTo(Referrals.TieredNetworkDigestStatus.validated)
        #expect(item.status == Referrals.TieredNetworkDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        item.status = Referrals.TieredNetworkDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredNetworkDigestStatus.created) }
    }
}
