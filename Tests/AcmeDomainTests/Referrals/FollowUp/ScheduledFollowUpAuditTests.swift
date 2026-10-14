@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpAuditTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        #expect(item.status == Referrals.ScheduledFollowUpAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        try item.moveTo(Referrals.ScheduledFollowUpAuditStatus.approved)
        #expect(item.status == Referrals.ScheduledFollowUpAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        item.status = Referrals.ScheduledFollowUpAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpAuditStatus.proposed) }
    }
}
