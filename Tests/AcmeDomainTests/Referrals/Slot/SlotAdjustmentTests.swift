@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotAdjustment("code-628", title: "title-947")
        #expect(item.status == Referrals.SlotAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newSlotAdjustment("code-628", title: "title-947")
        try item.moveTo(Referrals.SlotAdjustmentStatus.inReview)
        #expect(item.status == Referrals.SlotAdjustmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotAdjustment("code-628", title: "title-947")
        item.status = Referrals.SlotAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotAdjustmentStatus.`open`) }
    }
}
