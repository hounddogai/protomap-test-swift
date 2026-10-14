@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallReservationTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newCappedRecallReservation("code-817", name: "name-698")
        #expect(item.status == Pharmacy.CappedRecallReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newCappedRecallReservation("code-817", name: "name-698")
        try item.moveTo(Pharmacy.CappedRecallReservationStatus.inProgress)
        #expect(item.status == Pharmacy.CappedRecallReservationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newCappedRecallReservation("code-817", name: "name-698")
        item.status = Pharmacy.CappedRecallReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedRecallReservationStatus.planned) }
    }
}
