@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveReferralSummaryTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newAdaptiveReferralSummary("code-440", title: "title-469")
        #expect(item.status == Referrals.AdaptiveReferralSummaryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newAdaptiveReferralSummary("code-440", title: "title-469")
        try item.moveTo(Referrals.AdaptiveReferralSummaryStatus.inReview)
        #expect(item.status == Referrals.AdaptiveReferralSummaryStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newAdaptiveReferralSummary("code-440", title: "title-469")
        item.status = Referrals.AdaptiveReferralSummaryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveReferralSummaryStatus.`open`) }
    }
}
