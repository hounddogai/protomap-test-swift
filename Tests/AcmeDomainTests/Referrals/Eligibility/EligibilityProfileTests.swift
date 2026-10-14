@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProfileTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityProfile("code-879", label: "label-15")
        #expect(item.status == Referrals.EligibilityProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newEligibilityProfile("code-879", label: "label-15")
        try item.moveTo(Referrals.EligibilityProfileStatus.active)
        #expect(item.status == Referrals.EligibilityProfileStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityProfile("code-879", label: "label-15")
        item.status = Referrals.EligibilityProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityProfileStatus.draft) }
    }
}
