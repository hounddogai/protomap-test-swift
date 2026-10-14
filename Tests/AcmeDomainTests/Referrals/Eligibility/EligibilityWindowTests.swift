@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityWindowTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityWindow("code-121", label: "label-884")
        #expect(item.status == Referrals.EligibilityWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newEligibilityWindow("code-121", label: "label-884")
        try item.moveTo(Referrals.EligibilityWindowStatus.pending)
        #expect(item.status == Referrals.EligibilityWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityWindow("code-121", label: "label-884")
        item.status = Referrals.EligibilityWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityWindowStatus.draft) }
    }
}
