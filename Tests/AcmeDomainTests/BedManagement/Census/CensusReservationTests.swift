@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusReservationTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCensusReservation("code-540", title: "title-391")
        #expect(item.status == BedManagement.CensusReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newCensusReservation("code-540", title: "title-391")
        try item.moveTo(BedManagement.CensusReservationStatus.granted)
        #expect(item.status == BedManagement.CensusReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCensusReservation("code-540", title: "title-391")
        item.status = BedManagement.CensusReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusReservationStatus.requested) }
    }
}
