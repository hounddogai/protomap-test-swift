@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallReservationTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newPrimaryRecallReservation("code-3", label: "label-363")
        #expect(item.status == Pharmacy.PrimaryRecallReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newPrimaryRecallReservation("code-3", label: "label-363")
        try item.moveTo(Pharmacy.PrimaryRecallReservationStatus.granted)
        #expect(item.status == Pharmacy.PrimaryRecallReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newPrimaryRecallReservation("code-3", label: "label-363")
        item.status = Pharmacy.PrimaryRecallReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryRecallReservationStatus.requested) }
    }
}
