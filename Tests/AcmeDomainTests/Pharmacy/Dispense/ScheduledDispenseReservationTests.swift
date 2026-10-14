@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseReservationTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newScheduledDispenseReservation("code-153", name: "name-549")
        #expect(item.status == Pharmacy.ScheduledDispenseReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newScheduledDispenseReservation("code-153", name: "name-549")
        try item.moveTo(Pharmacy.ScheduledDispenseReservationStatus.withdrawn)
        #expect(item.status == Pharmacy.ScheduledDispenseReservationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newScheduledDispenseReservation("code-153", name: "name-549")
        item.status = Pharmacy.ScheduledDispenseReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledDispenseReservationStatus.proposed) }
    }
}
