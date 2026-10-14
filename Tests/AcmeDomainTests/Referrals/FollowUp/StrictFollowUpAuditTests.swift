@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAuditTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newStrictFollowUpAudit("code-40", title: "title-223")
        #expect(item.status == Referrals.StrictFollowUpAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newStrictFollowUpAudit("code-40", title: "title-223")
        try item.moveTo(Referrals.StrictFollowUpAuditStatus.pending)
        #expect(item.status == Referrals.StrictFollowUpAuditStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newStrictFollowUpAudit("code-40", title: "title-223")
        item.status = Referrals.StrictFollowUpAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictFollowUpAuditStatus.draft) }
    }
}
