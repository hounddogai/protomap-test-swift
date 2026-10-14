@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyReservationTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularyReservation("code-481", label: "label-826")
        #expect(item.status == Pharmacy.FormularyReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newFormularyReservation("code-481", label: "label-826")
        try item.moveTo(Pharmacy.FormularyReservationStatus.validated)
        #expect(item.status == Pharmacy.FormularyReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularyReservation("code-481", label: "label-826")
        item.status = Pharmacy.FormularyReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyReservationStatus.created) }
    }
}
