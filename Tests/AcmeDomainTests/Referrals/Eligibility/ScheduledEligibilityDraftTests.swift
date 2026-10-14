@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityDraftTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        #expect(item.status == Referrals.ScheduledEligibilityDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        try item.moveTo(Referrals.ScheduledEligibilityDraftStatus.done)
        #expect(item.status == Referrals.ScheduledEligibilityDraftStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        item.status = Referrals.ScheduledEligibilityDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledEligibilityDraftStatus.new) }
    }
}
