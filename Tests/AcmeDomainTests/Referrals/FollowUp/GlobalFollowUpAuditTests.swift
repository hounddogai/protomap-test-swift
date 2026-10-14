@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpAuditTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newGlobalFollowUpAudit("code-54", label: "label-17")
        #expect(item.status == Referrals.GlobalFollowUpAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newGlobalFollowUpAudit("code-54", label: "label-17")
        try item.moveTo(Referrals.GlobalFollowUpAuditStatus.granted)
        #expect(item.status == Referrals.GlobalFollowUpAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newGlobalFollowUpAudit("code-54", label: "label-17")
        item.status = Referrals.GlobalFollowUpAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalFollowUpAuditStatus.requested) }
    }
}
