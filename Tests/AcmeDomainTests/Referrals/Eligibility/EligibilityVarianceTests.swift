@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityVarianceTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        #expect(item.status == Referrals.EligibilityVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        try item.moveTo(Referrals.EligibilityVarianceStatus.queued)
        #expect(item.status == Referrals.EligibilityVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        item.status = Referrals.EligibilityVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityVarianceStatus.new) }
    }
}
