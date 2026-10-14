@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotThresholdTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newRollingSlotThreshold("code-616", title: "title-35")
        #expect(item.status == Referrals.RollingSlotThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newRollingSlotThreshold("code-616", title: "title-35")
        try item.moveTo(Referrals.RollingSlotThresholdStatus.active)
        #expect(item.status == Referrals.RollingSlotThresholdStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newRollingSlotThreshold("code-616", title: "title-35")
        item.status = Referrals.RollingSlotThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingSlotThresholdStatus.draft) }
    }
}
