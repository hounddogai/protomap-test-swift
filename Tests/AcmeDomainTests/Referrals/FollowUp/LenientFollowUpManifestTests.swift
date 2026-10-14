@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpManifestTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLenientFollowUpManifest("code-291", title: "title-556")
        #expect(item.status == Referrals.LenientFollowUpManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newLenientFollowUpManifest("code-291", title: "title-556")
        try item.moveTo(Referrals.LenientFollowUpManifestStatus.inReview)
        #expect(item.status == Referrals.LenientFollowUpManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLenientFollowUpManifest("code-291", title: "title-556")
        item.status = Referrals.LenientFollowUpManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientFollowUpManifestStatus.`open`) }
    }
}
