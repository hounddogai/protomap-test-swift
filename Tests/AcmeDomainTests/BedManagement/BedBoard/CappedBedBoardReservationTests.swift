@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardReservationTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCappedBedBoardReservation("code-309", name: "name-579")
        #expect(item.status == BedManagement.CappedBedBoardReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCappedBedBoardReservation("code-309", name: "name-579")
        try item.moveTo(BedManagement.CappedBedBoardReservationStatus.inReview)
        #expect(item.status == BedManagement.CappedBedBoardReservationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCappedBedBoardReservation("code-309", name: "name-579")
        item.status = BedManagement.CappedBedBoardReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedBedBoardReservationStatus.`open`) }
    }
}
