@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMetricTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newEligibilityMetric("code-964", title: "title-423")
        #expect(item.status == Referrals.EligibilityMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newEligibilityMetric("code-964", title: "title-423")
        try item.moveTo(Referrals.EligibilityMetricStatus.validated)
        #expect(item.status == Referrals.EligibilityMetricStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newEligibilityMetric("code-964", title: "title-423")
        item.status = Referrals.EligibilityMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityMetricStatus.created) }
    }
}
