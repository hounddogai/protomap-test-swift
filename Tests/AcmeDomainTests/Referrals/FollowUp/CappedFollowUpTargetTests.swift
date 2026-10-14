@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpTargetTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newCappedFollowUpTarget("code-230", title: "title-79")
        #expect(item.status == Referrals.CappedFollowUpTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newCappedFollowUpTarget("code-230", title: "title-79")
        try item.moveTo(Referrals.CappedFollowUpTargetStatus.inReview)
        #expect(item.status == Referrals.CappedFollowUpTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newCappedFollowUpTarget("code-230", title: "title-79")
        item.status = Referrals.CappedFollowUpTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedFollowUpTargetStatus.`open`) }
    }
}
