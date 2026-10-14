@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedNetworkQuotaTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newWeightedNetworkQuota("code-273", name: "name-30")
        #expect(item.status == Referrals.WeightedNetworkQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newWeightedNetworkQuota("code-273", name: "name-30")
        try item.moveTo(Referrals.WeightedNetworkQuotaStatus.ready)
        #expect(item.status == Referrals.WeightedNetworkQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newWeightedNetworkQuota("code-273", name: "name-30")
        item.status = Referrals.WeightedNetworkQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedNetworkQuotaStatus.idle) }
    }
}
