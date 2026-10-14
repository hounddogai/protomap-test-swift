@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralCycleTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        #expect(item.status == Referrals.GlobalReferralCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        try item.moveTo(Referrals.GlobalReferralCycleStatus.inReview)
        #expect(item.status == Referrals.GlobalReferralCycleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        item.status = Referrals.GlobalReferralCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalReferralCycleStatus.`open`) }
    }
}
