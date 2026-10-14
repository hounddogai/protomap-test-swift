@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningReservationTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDefaultCleaningReservation("code-430", label: "label-518")
        #expect(item.status == BedManagement.DefaultCleaningReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDefaultCleaningReservation("code-430", label: "label-518")
        try item.moveTo(BedManagement.DefaultCleaningReservationStatus.warming)
        #expect(item.status == BedManagement.DefaultCleaningReservationStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDefaultCleaningReservation("code-430", label: "label-518")
        item.status = BedManagement.DefaultCleaningReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCleaningReservationStatus.idle) }
    }
}
