@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityTemplateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFallbackEligibilityTemplate("code-15", label: "label-494")
        #expect(item.status == Referrals.FallbackEligibilityTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newFallbackEligibilityTemplate("code-15", label: "label-494")
        try item.moveTo(Referrals.FallbackEligibilityTemplateStatus.granted)
        #expect(item.status == Referrals.FallbackEligibilityTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFallbackEligibilityTemplate("code-15", label: "label-494")
        item.status = Referrals.FallbackEligibilityTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackEligibilityTemplateStatus.requested) }
    }
}
