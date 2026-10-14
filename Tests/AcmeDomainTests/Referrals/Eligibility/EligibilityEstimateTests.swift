@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityEstimateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newEligibilityEstimate("code-424", title: "title-570")
        #expect(item.status == Referrals.EligibilityEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newEligibilityEstimate("code-424", title: "title-570")
        try item.moveTo(Referrals.EligibilityEstimateStatus.granted)
        #expect(item.status == Referrals.EligibilityEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newEligibilityEstimate("code-424", title: "title-570")
        item.status = Referrals.EligibilityEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityEstimateStatus.requested) }
    }
}
