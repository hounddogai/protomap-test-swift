@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackFollowUpBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFallbackFollowUpBaseline("code-810", label: "label-467")
        #expect(item.status == Referrals.FallbackFollowUpBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newFallbackFollowUpBaseline("code-810", label: "label-467")
        try item.moveTo(Referrals.FallbackFollowUpBaselineStatus.completed)
        #expect(item.status == Referrals.FallbackFollowUpBaselineStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFallbackFollowUpBaseline("code-810", label: "label-467")
        item.status = Referrals.FallbackFollowUpBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackFollowUpBaselineStatus.planned) }
    }
}
