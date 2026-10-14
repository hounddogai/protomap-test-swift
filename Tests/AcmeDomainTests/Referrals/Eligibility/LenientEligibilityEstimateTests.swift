@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilityEstimateTests {
    @Test func startsInNew() throws {
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        #expect(item.status == Referrals.LenientEligibilityEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        try item.moveTo(Referrals.LenientEligibilityEstimateStatus.queued)
        #expect(item.status == Referrals.LenientEligibilityEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        item.status = Referrals.LenientEligibilityEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientEligibilityEstimateStatus.new) }
    }
}
