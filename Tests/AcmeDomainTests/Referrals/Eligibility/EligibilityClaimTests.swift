@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityClaimTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityClaim("code-252", title: "title-920")
        #expect(item.status == Referrals.EligibilityClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newEligibilityClaim("code-252", title: "title-920")
        try item.moveTo(Referrals.EligibilityClaimStatus.active)
        #expect(item.status == Referrals.EligibilityClaimStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityClaim("code-252", title: "title-920")
        item.status = Referrals.EligibilityClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityClaimStatus.draft) }
    }
}
