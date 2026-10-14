@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpRequestTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newScheduledFollowUpRequest("code-162", label: "label-950")
        #expect(item.status == Referrals.ScheduledFollowUpRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newScheduledFollowUpRequest("code-162", label: "label-950")
        try item.moveTo(Referrals.ScheduledFollowUpRequestStatus.active)
        #expect(item.status == Referrals.ScheduledFollowUpRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newScheduledFollowUpRequest("code-162", label: "label-950")
        item.status = Referrals.ScheduledFollowUpRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpRequestStatus.draft) }
    }
}
