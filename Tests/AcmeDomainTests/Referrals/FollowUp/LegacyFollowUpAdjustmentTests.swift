@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLegacyFollowUpAdjustment("code-854", name: "name-628")
        #expect(item.status == Referrals.LegacyFollowUpAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newLegacyFollowUpAdjustment("code-854", name: "name-628")
        try item.moveTo(Referrals.LegacyFollowUpAdjustmentStatus.validated)
        #expect(item.status == Referrals.LegacyFollowUpAdjustmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLegacyFollowUpAdjustment("code-854", name: "name-628")
        item.status = Referrals.LegacyFollowUpAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyFollowUpAdjustmentStatus.created) }
    }
}
