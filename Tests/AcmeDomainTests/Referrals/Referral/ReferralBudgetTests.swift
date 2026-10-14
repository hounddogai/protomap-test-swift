@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralBudgetTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newReferralBudget("code-440", title: "title-459")
        #expect(item.status == Referrals.ReferralBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newReferralBudget("code-440", title: "title-459")
        try item.moveTo(Referrals.ReferralBudgetStatus.published)
        #expect(item.status == Referrals.ReferralBudgetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newReferralBudget("code-440", title: "title-459")
        item.status = Referrals.ReferralBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralBudgetStatus.created) }
    }
}
