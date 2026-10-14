@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpEntryTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpEntry("code-502", name: "name-507")
        #expect(item.status == Referrals.FollowUpEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newFollowUpEntry("code-502", name: "name-507")
        try item.moveTo(Referrals.FollowUpEntryStatus.suspended)
        #expect(item.status == Referrals.FollowUpEntryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpEntry("code-502", name: "name-507")
        item.status = Referrals.FollowUpEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpEntryStatus.draft) }
    }
}
