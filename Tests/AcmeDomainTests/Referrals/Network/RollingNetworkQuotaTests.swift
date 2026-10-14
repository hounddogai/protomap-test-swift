@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingNetworkQuotaTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newRollingNetworkQuota("code-713", label: "label-614")
        #expect(item.status == Referrals.RollingNetworkQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newRollingNetworkQuota("code-713", label: "label-614")
        try item.moveTo(Referrals.RollingNetworkQuotaStatus.granted)
        #expect(item.status == Referrals.RollingNetworkQuotaStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newRollingNetworkQuota("code-713", label: "label-614")
        item.status = Referrals.RollingNetworkQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingNetworkQuotaStatus.requested) }
    }
}
