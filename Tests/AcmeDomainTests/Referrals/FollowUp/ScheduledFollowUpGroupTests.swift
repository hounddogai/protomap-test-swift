@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpGroupTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newScheduledFollowUpGroup("code-413", name: "name-330")
        #expect(item.status == Referrals.ScheduledFollowUpGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newScheduledFollowUpGroup("code-413", name: "name-330")
        try item.moveTo(Referrals.ScheduledFollowUpGroupStatus.revoked)
        #expect(item.status == Referrals.ScheduledFollowUpGroupStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newScheduledFollowUpGroup("code-413", name: "name-330")
        item.status = Referrals.ScheduledFollowUpGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpGroupStatus.requested) }
    }
}
