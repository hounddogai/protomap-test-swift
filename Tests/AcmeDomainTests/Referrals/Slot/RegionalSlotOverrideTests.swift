@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotOverrideTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRegionalSlotOverride("code-748", name: "name-841")
        #expect(item.status == Referrals.RegionalSlotOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Referrals.newRegionalSlotOverride("code-748", name: "name-841")
        try item.moveTo(Referrals.RegionalSlotOverrideStatus.withdrawn)
        #expect(item.status == Referrals.RegionalSlotOverrideStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRegionalSlotOverride("code-748", name: "name-841")
        item.status = Referrals.RegionalSlotOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalSlotOverrideStatus.proposed) }
    }
}
