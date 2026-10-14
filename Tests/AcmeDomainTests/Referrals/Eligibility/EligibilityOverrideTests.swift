@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityOverrideTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newEligibilityOverride("code-502", title: "title-866")
        #expect(item.status == Referrals.EligibilityOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newEligibilityOverride("code-502", title: "title-866")
        try item.moveTo(Referrals.EligibilityOverrideStatus.ready)
        #expect(item.status == Referrals.EligibilityOverrideStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newEligibilityOverride("code-502", title: "title-866")
        item.status = Referrals.EligibilityOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityOverrideStatus.idle) }
    }
}
