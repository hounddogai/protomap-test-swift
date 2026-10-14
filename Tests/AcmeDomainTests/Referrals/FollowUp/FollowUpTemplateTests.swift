@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTemplateTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpTemplate("code-950", label: "label-935")
        #expect(item.status == Referrals.FollowUpTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newFollowUpTemplate("code-950", label: "label-935")
        try item.moveTo(Referrals.FollowUpTemplateStatus.pending)
        #expect(item.status == Referrals.FollowUpTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpTemplate("code-950", label: "label-935")
        item.status = Referrals.FollowUpTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpTemplateStatus.draft) }
    }
}
