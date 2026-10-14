@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningReservationTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        #expect(item.status == BedManagement.TieredCleaningReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        try item.moveTo(BedManagement.TieredCleaningReservationStatus.inProgress)
        #expect(item.status == BedManagement.TieredCleaningReservationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        item.status = BedManagement.TieredCleaningReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredCleaningReservationStatus.planned) }
    }
}
