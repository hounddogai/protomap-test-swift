@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpGroupTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFollowUpGroup("code-573", name: "name-737")
        #expect(item.status == Referrals.FollowUpGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newFollowUpGroup("code-573", name: "name-737")
        try item.moveTo(Referrals.FollowUpGroupStatus.granted)
        #expect(item.status == Referrals.FollowUpGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFollowUpGroup("code-573", name: "name-737")
        item.status = Referrals.FollowUpGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpGroupStatus.requested) }
    }
}
