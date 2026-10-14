@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotThresholdTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSlotThreshold("code-779", title: "title-331")
        #expect(item.status == Referrals.SlotThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newSlotThreshold("code-779", title: "title-331")
        try item.moveTo(Referrals.SlotThresholdStatus.rejected)
        #expect(item.status == Referrals.SlotThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSlotThreshold("code-779", title: "title-331")
        item.status = Referrals.SlotThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotThresholdStatus.proposed) }
    }
}
