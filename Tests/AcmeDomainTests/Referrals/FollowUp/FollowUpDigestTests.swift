@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpDigestTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpDigest("code-724", label: "label-306")
        #expect(item.status == Referrals.FollowUpDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newFollowUpDigest("code-724", label: "label-306")
        try item.moveTo(Referrals.FollowUpDigestStatus.closed)
        #expect(item.status == Referrals.FollowUpDigestStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpDigest("code-724", label: "label-306")
        item.status = Referrals.FollowUpDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpDigestStatus.draft) }
    }
}
