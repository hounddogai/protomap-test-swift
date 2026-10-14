@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpWindowTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newFollowUpWindow("code-970", title: "title-274")
        #expect(item.status == Referrals.FollowUpWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newFollowUpWindow("code-970", title: "title-274")
        try item.moveTo(Referrals.FollowUpWindowStatus.ready)
        #expect(item.status == Referrals.FollowUpWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newFollowUpWindow("code-970", title: "title-274")
        item.status = Referrals.FollowUpWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpWindowStatus.idle) }
    }
}
