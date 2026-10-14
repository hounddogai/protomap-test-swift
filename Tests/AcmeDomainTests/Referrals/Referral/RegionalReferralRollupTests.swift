@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalReferralRollupTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newRegionalReferralRollup("code-996", title: "title-781")
        #expect(item.status == Referrals.RegionalReferralRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newRegionalReferralRollup("code-996", title: "title-781")
        try item.moveTo(Referrals.RegionalReferralRollupStatus.ready)
        #expect(item.status == Referrals.RegionalReferralRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newRegionalReferralRollup("code-996", title: "title-781")
        item.status = Referrals.RegionalReferralRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalReferralRollupStatus.idle) }
    }
}
