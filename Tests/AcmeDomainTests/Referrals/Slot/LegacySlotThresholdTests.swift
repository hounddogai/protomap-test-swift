@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotThresholdTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newLegacySlotThreshold("code-992", label: "label-903")
        #expect(item.status == Referrals.LegacySlotThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newLegacySlotThreshold("code-992", label: "label-903")
        try item.moveTo(Referrals.LegacySlotThresholdStatus.rejected)
        #expect(item.status == Referrals.LegacySlotThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newLegacySlotThreshold("code-992", label: "label-903")
        item.status = Referrals.LegacySlotThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacySlotThresholdStatus.proposed) }
    }
}
