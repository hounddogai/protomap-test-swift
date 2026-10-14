@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBaselineTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newEligibilityBaseline("code-600", label: "label-858")
        #expect(item.status == Referrals.EligibilityBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newEligibilityBaseline("code-600", label: "label-858")
        try item.moveTo(Referrals.EligibilityBaselineStatus.granted)
        #expect(item.status == Referrals.EligibilityBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newEligibilityBaseline("code-600", label: "label-858")
        item.status = Referrals.EligibilityBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityBaselineStatus.requested) }
    }
}
