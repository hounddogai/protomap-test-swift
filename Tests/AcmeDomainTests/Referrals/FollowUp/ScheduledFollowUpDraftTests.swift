@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpDraftTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledFollowUpDraft("code-445", label: "label-542")
        #expect(item.status == Referrals.ScheduledFollowUpDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newScheduledFollowUpDraft("code-445", label: "label-542")
        try item.moveTo(Referrals.ScheduledFollowUpDraftStatus.running)
        #expect(item.status == Referrals.ScheduledFollowUpDraftStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledFollowUpDraft("code-445", label: "label-542")
        item.status = Referrals.ScheduledFollowUpDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpDraftStatus.new) }
    }
}
