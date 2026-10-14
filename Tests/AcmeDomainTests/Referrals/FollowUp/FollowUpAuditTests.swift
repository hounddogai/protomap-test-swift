@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAuditTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newFollowUpAudit("code-226", label: "label-140")
        #expect(item.status == Referrals.FollowUpAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newFollowUpAudit("code-226", label: "label-140")
        try item.moveTo(Referrals.FollowUpAuditStatus.ready)
        #expect(item.status == Referrals.FollowUpAuditStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newFollowUpAudit("code-226", label: "label-140")
        item.status = Referrals.FollowUpAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpAuditStatus.idle) }
    }
}
