@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpPolicyTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newAdaptiveFollowUpPolicy("code-883", label: "label-529")
        #expect(item.status == Referrals.AdaptiveFollowUpPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newAdaptiveFollowUpPolicy("code-883", label: "label-529")
        try item.moveTo(Referrals.AdaptiveFollowUpPolicyStatus.validated)
        #expect(item.status == Referrals.AdaptiveFollowUpPolicyStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newAdaptiveFollowUpPolicy("code-883", label: "label-529")
        item.status = Referrals.AdaptiveFollowUpPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveFollowUpPolicyStatus.created) }
    }
}
