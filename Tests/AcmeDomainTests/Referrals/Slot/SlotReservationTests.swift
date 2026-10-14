@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotReservationTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotReservation("code-769", title: "title-71")
        #expect(item.status == Referrals.SlotReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newSlotReservation("code-769", title: "title-71")
        try item.moveTo(Referrals.SlotReservationStatus.running)
        #expect(item.status == Referrals.SlotReservationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotReservation("code-769", title: "title-71")
        item.status = Referrals.SlotReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotReservationStatus.new) }
    }
}
