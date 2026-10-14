@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotRollupTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newRollingSlotRollup("code-688", label: "label-355")
        #expect(item.status == Referrals.RollingSlotRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newRollingSlotRollup("code-688", label: "label-355")
        try item.moveTo(Referrals.RollingSlotRollupStatus.published)
        #expect(item.status == Referrals.RollingSlotRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newRollingSlotRollup("code-688", label: "label-355")
        item.status = Referrals.RollingSlotRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingSlotRollupStatus.created) }
    }
}
