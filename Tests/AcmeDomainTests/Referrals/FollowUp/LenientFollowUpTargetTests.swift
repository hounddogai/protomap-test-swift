@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpTargetTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLenientFollowUpTarget("code-543", title: "title-986")
        #expect(item.status == Referrals.LenientFollowUpTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newLenientFollowUpTarget("code-543", title: "title-986")
        try item.moveTo(Referrals.LenientFollowUpTargetStatus.inReview)
        #expect(item.status == Referrals.LenientFollowUpTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLenientFollowUpTarget("code-543", title: "title-986")
        item.status = Referrals.LenientFollowUpTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientFollowUpTargetStatus.`open`) }
    }
}
