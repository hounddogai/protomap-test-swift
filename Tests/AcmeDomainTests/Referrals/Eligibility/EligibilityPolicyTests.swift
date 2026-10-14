@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPolicyTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityPolicy("code-852", name: "name-562")
        #expect(item.status == Referrals.EligibilityPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newEligibilityPolicy("code-852", name: "name-562")
        try item.moveTo(Referrals.EligibilityPolicyStatus.suspended)
        #expect(item.status == Referrals.EligibilityPolicyStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityPolicy("code-852", name: "name-562")
        item.status = Referrals.EligibilityPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityPolicyStatus.draft) }
    }
}
