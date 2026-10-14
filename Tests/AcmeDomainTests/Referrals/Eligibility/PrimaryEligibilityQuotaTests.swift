@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityQuotaTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        #expect(item.status == Referrals.PrimaryEligibilityQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        try item.moveTo(Referrals.PrimaryEligibilityQuotaStatus.granted)
        #expect(item.status == Referrals.PrimaryEligibilityQuotaStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        item.status = Referrals.PrimaryEligibilityQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryEligibilityQuotaStatus.requested) }
    }
}
