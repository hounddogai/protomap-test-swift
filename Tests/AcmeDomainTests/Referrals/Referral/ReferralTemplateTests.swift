@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralTemplateTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newReferralTemplate("code-625", title: "title-697")
        #expect(item.status == Referrals.ReferralTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newReferralTemplate("code-625", title: "title-697")
        try item.moveTo(Referrals.ReferralTemplateStatus.pending)
        #expect(item.status == Referrals.ReferralTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newReferralTemplate("code-625", title: "title-697")
        item.status = Referrals.ReferralTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralTemplateStatus.draft) }
    }
}
