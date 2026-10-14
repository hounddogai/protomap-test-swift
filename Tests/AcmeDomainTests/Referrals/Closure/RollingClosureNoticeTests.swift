@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureNoticeTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRollingClosureNotice("code-122", title: "title-535")
        #expect(item.status == Referrals.RollingClosureNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newRollingClosureNotice("code-122", title: "title-535")
        try item.moveTo(Referrals.RollingClosureNoticeStatus.approved)
        #expect(item.status == Referrals.RollingClosureNoticeStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRollingClosureNotice("code-122", title: "title-535")
        item.status = Referrals.RollingClosureNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingClosureNoticeStatus.proposed) }
    }
}
