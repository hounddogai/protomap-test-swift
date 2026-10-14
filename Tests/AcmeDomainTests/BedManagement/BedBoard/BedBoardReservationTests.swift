@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardReservationTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newBedBoardReservation("code-35", label: "label-101")
        #expect(item.status == BedManagement.BedBoardReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newBedBoardReservation("code-35", label: "label-101")
        try item.moveTo(BedManagement.BedBoardReservationStatus.published)
        #expect(item.status == BedManagement.BedBoardReservationStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newBedBoardReservation("code-35", label: "label-101")
        item.status = BedManagement.BedBoardReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardReservationStatus.created) }
    }
}
