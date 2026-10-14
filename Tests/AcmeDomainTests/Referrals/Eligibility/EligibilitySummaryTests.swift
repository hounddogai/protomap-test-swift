@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySummaryTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newEligibilitySummary("code-269", title: "title-555")
        #expect(item.status == Referrals.EligibilitySummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newEligibilitySummary("code-269", title: "title-555")
        try item.moveTo(Referrals.EligibilitySummaryStatus.validated)
        #expect(item.status == Referrals.EligibilitySummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newEligibilitySummary("code-269", title: "title-555")
        item.status = Referrals.EligibilitySummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilitySummaryStatus.created) }
    }
}
