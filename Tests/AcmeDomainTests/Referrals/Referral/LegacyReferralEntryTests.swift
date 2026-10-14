@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralEntryTests {
    @Test func startsInNew() throws {
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        #expect(item.status == Referrals.LegacyReferralEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        try item.moveTo(Referrals.LegacyReferralEntryStatus.queued)
        #expect(item.status == Referrals.LegacyReferralEntryStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        item.status = Referrals.LegacyReferralEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyReferralEntryStatus.new) }
    }
}
