@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRollupTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newReferralRollup("code-959", label: "label-641")
        #expect(item.status == Referrals.ReferralRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newReferralRollup("code-959", label: "label-641")
        try item.moveTo(Referrals.ReferralRollupStatus.warming)
        #expect(item.status == Referrals.ReferralRollupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newReferralRollup("code-959", label: "label-641")
        item.status = Referrals.ReferralRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralRollupStatus.idle) }
    }
}
