@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkQuotaTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newNetworkQuota("code-151", title: "title-465")
        #expect(item.status == Referrals.NetworkQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newNetworkQuota("code-151", title: "title-465")
        try item.moveTo(Referrals.NetworkQuotaStatus.revoked)
        #expect(item.status == Referrals.NetworkQuotaStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newNetworkQuota("code-151", title: "title-465")
        item.status = Referrals.NetworkQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkQuotaStatus.requested) }
    }
}
