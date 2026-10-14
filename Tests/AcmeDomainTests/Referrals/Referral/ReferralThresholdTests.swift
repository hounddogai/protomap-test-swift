@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralThresholdTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newReferralThreshold("code-728", name: "name-876")
        #expect(item.status == Referrals.ReferralThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newReferralThreshold("code-728", name: "name-876")
        try item.moveTo(Referrals.ReferralThresholdStatus.warming)
        #expect(item.status == Referrals.ReferralThresholdStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newReferralThreshold("code-728", name: "name-876")
        item.status = Referrals.ReferralThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralThresholdStatus.idle) }
    }
}
