@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardReservationTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newPrimaryBedBoardReservation("code-242", name: "name-415")
        #expect(item.status == BedManagement.PrimaryBedBoardReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newPrimaryBedBoardReservation("code-242", name: "name-415")
        try item.moveTo(BedManagement.PrimaryBedBoardReservationStatus.validated)
        #expect(item.status == BedManagement.PrimaryBedBoardReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newPrimaryBedBoardReservation("code-242", name: "name-415")
        item.status = BedManagement.PrimaryBedBoardReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryBedBoardReservationStatus.created) }
    }
}
