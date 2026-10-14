@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotItemTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newSlotItem("code-782", label: "label-562")
        #expect(item.status == Referrals.SlotItemStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newSlotItem("code-782", label: "label-562")
        try item.moveTo(Referrals.SlotItemStatus.granted)
        #expect(item.status == Referrals.SlotItemStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newSlotItem("code-782", label: "label-562")
        item.status = Referrals.SlotItemStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotItemStatus.requested) }
    }
}
