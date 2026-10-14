@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotSummaryTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newSlotSummary("code-702", title: "title-250")
        #expect(item.status == Referrals.SlotSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newSlotSummary("code-702", title: "title-250")
        try item.moveTo(Referrals.SlotSummaryStatus.published)
        #expect(item.status == Referrals.SlotSummaryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newSlotSummary("code-702", title: "title-250")
        item.status = Referrals.SlotSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotSummaryStatus.created) }
    }
}
