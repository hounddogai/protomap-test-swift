@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingEligibilityVariance("code-970", title: "title-309")
        #expect(item.status == Referrals.PendingEligibilityVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newPendingEligibilityVariance("code-970", title: "title-309")
        try item.moveTo(Referrals.PendingEligibilityVarianceStatus.scheduled)
        #expect(item.status == Referrals.PendingEligibilityVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingEligibilityVariance("code-970", title: "title-309")
        item.status = Referrals.PendingEligibilityVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingEligibilityVarianceStatus.planned) }
    }
}
