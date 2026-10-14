@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkDigestTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newNetworkDigest("code-883", name: "name-91")
        #expect(item.status == Referrals.NetworkDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newNetworkDigest("code-883", name: "name-91")
        try item.moveTo(Referrals.NetworkDigestStatus.validated)
        #expect(item.status == Referrals.NetworkDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newNetworkDigest("code-883", name: "name-91")
        item.status = Referrals.NetworkDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkDigestStatus.created) }
    }
}
