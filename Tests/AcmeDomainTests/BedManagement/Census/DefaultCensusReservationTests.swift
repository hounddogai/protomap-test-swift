@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCensusReservationTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newDefaultCensusReservation("code-107", name: "name-237")
        #expect(item.status == BedManagement.DefaultCensusReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newDefaultCensusReservation("code-107", name: "name-237")
        try item.moveTo(BedManagement.DefaultCensusReservationStatus.running)
        #expect(item.status == BedManagement.DefaultCensusReservationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newDefaultCensusReservation("code-107", name: "name-237")
        item.status = BedManagement.DefaultCensusReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCensusReservationStatus.new) }
    }
}
