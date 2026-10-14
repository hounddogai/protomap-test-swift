@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMetricTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosureMetric("code-285", title: "title-883")
        #expect(item.status == Referrals.ClosureMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newClosureMetric("code-285", title: "title-883")
        try item.moveTo(Referrals.ClosureMetricStatus.revoked)
        #expect(item.status == Referrals.ClosureMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosureMetric("code-285", title: "title-883")
        item.status = Referrals.ClosureMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureMetricStatus.requested) }
    }
}
