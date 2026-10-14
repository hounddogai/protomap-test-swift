@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityNoticeTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newRegionalEligibilityNotice("code-844", title: "title-884")
        #expect(item.status == Referrals.RegionalEligibilityNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newRegionalEligibilityNotice("code-844", title: "title-884")
        try item.moveTo(Referrals.RegionalEligibilityNoticeStatus.active)
        #expect(item.status == Referrals.RegionalEligibilityNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newRegionalEligibilityNotice("code-844", title: "title-884")
        item.status = Referrals.RegionalEligibilityNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalEligibilityNoticeStatus.draft) }
    }
}
