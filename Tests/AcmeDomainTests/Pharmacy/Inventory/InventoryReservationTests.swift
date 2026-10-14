@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReservationTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInventoryReservation("code-293", label: "label-326")
        #expect(item.status == Pharmacy.InventoryReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newInventoryReservation("code-293", label: "label-326")
        try item.moveTo(Pharmacy.InventoryReservationStatus.stopped)
        #expect(item.status == Pharmacy.InventoryReservationStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInventoryReservation("code-293", label: "label-326")
        item.status = Pharmacy.InventoryReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryReservationStatus.idle) }
    }
}
