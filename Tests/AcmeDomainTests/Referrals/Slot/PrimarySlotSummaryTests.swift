@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotSummaryTests {
    @Test func startsInNew() throws {
        let item = Referrals.newPrimarySlotSummary("code-409", title: "title-746")
        #expect(item.status == Referrals.PrimarySlotSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newPrimarySlotSummary("code-409", title: "title-746")
        try item.moveTo(Referrals.PrimarySlotSummaryStatus.failed)
        #expect(item.status == Referrals.PrimarySlotSummaryStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newPrimarySlotSummary("code-409", title: "title-746")
        item.status = Referrals.PrimarySlotSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimarySlotSummaryStatus.new) }
    }
}
