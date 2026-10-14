@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newFollowUpAssignment("code-544", title: "title-947")
        #expect(item.status == Referrals.FollowUpAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newFollowUpAssignment("code-544", title: "title-947")
        try item.moveTo(Referrals.FollowUpAssignmentStatus.retired)
        #expect(item.status == Referrals.FollowUpAssignmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newFollowUpAssignment("code-544", title: "title-947")
        item.status = Referrals.FollowUpAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpAssignmentStatus.created) }
    }
}
