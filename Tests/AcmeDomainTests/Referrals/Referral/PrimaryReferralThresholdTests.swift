@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralThresholdTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newPrimaryReferralThreshold("code-293", label: "label-200")
        #expect(item.status == Referrals.PrimaryReferralThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newPrimaryReferralThreshold("code-293", label: "label-200")
        try item.moveTo(Referrals.PrimaryReferralThresholdStatus.published)
        #expect(item.status == Referrals.PrimaryReferralThresholdStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newPrimaryReferralThreshold("code-293", label: "label-200")
        item.status = Referrals.PrimaryReferralThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryReferralThresholdStatus.created) }
    }
}
