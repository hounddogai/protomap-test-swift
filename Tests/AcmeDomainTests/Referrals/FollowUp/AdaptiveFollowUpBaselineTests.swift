@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpBaselineTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newAdaptiveFollowUpBaseline("code-321", title: "title-742")
        #expect(item.status == Referrals.AdaptiveFollowUpBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newAdaptiveFollowUpBaseline("code-321", title: "title-742")
        try item.moveTo(Referrals.AdaptiveFollowUpBaselineStatus.pending)
        #expect(item.status == Referrals.AdaptiveFollowUpBaselineStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newAdaptiveFollowUpBaseline("code-321", title: "title-742")
        item.status = Referrals.AdaptiveFollowUpBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveFollowUpBaselineStatus.draft) }
    }
}
