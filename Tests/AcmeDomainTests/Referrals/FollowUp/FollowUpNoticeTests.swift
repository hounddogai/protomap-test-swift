@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpNoticeTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newFollowUpNotice("code-495", name: "name-413")
        #expect(item.status == Referrals.FollowUpNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newFollowUpNotice("code-495", name: "name-413")
        try item.moveTo(Referrals.FollowUpNoticeStatus.validated)
        #expect(item.status == Referrals.FollowUpNoticeStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newFollowUpNotice("code-495", name: "name-413")
        item.status = Referrals.FollowUpNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpNoticeStatus.created) }
    }
}
