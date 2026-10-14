@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingFollowUpNoticeTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newPendingFollowUpNotice("code-18", title: "title-95")
        #expect(item.status == Referrals.PendingFollowUpNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newPendingFollowUpNotice("code-18", title: "title-95")
        try item.moveTo(Referrals.PendingFollowUpNoticeStatus.draining)
        #expect(item.status == Referrals.PendingFollowUpNoticeStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newPendingFollowUpNotice("code-18", title: "title-95")
        item.status = Referrals.PendingFollowUpNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingFollowUpNoticeStatus.idle) }
    }
}
