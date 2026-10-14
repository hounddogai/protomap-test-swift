@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReservationTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newPendingFormularyReservation("code-106", name: "name-428")
        #expect(item.status == Pharmacy.PendingFormularyReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newPendingFormularyReservation("code-106", name: "name-428")
        try item.moveTo(Pharmacy.PendingFormularyReservationStatus.rejected)
        #expect(item.status == Pharmacy.PendingFormularyReservationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newPendingFormularyReservation("code-106", name: "name-428")
        item.status = Pharmacy.PendingFormularyReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingFormularyReservationStatus.proposed) }
    }
}
