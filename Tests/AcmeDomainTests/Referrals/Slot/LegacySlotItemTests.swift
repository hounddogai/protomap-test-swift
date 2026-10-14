@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotItemTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newLegacySlotItem("code-939", title: "title-61")
        #expect(item.status == Referrals.LegacySlotItemStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newLegacySlotItem("code-939", title: "title-61")
        try item.moveTo(Referrals.LegacySlotItemStatus.granted)
        #expect(item.status == Referrals.LegacySlotItemStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newLegacySlotItem("code-939", title: "title-61")
        item.status = Referrals.LegacySlotItemStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacySlotItemStatus.requested) }
    }
}
