@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMappingTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpMapping("code-661", title: "title-19")
        #expect(item.status == Referrals.FollowUpMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newFollowUpMapping("code-661", title: "title-19")
        try item.moveTo(Referrals.FollowUpMappingStatus.closed)
        #expect(item.status == Referrals.FollowUpMappingStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpMapping("code-661", title: "title-19")
        item.status = Referrals.FollowUpMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpMappingStatus.draft) }
    }
}
