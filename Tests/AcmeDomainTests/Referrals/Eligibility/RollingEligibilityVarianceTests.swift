@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilityVarianceTests {
    @Test func startsInNew() throws {
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        #expect(item.status == Referrals.RollingEligibilityVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        try item.moveTo(Referrals.RollingEligibilityVarianceStatus.running)
        #expect(item.status == Referrals.RollingEligibilityVarianceStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        item.status = Referrals.RollingEligibilityVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingEligibilityVarianceStatus.new) }
    }
}
