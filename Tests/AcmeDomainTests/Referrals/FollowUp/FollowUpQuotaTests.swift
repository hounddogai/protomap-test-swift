@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpQuotaTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newFollowUpQuota("code-483", label: "label-655")
        #expect(item.status == Referrals.FollowUpQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newFollowUpQuota("code-483", label: "label-655")
        try item.moveTo(Referrals.FollowUpQuotaStatus.validated)
        #expect(item.status == Referrals.FollowUpQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newFollowUpQuota("code-483", label: "label-655")
        item.status = Referrals.FollowUpQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpQuotaStatus.created) }
    }
}
