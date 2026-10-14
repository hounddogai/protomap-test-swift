@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningReservationTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newAdaptiveCleaningReservation("code-677", name: "name-118")
        #expect(item.status == BedManagement.AdaptiveCleaningReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newAdaptiveCleaningReservation("code-677", name: "name-118")
        try item.moveTo(BedManagement.AdaptiveCleaningReservationStatus.granted)
        #expect(item.status == BedManagement.AdaptiveCleaningReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newAdaptiveCleaningReservation("code-677", name: "name-118")
        item.status = BedManagement.AdaptiveCleaningReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningReservationStatus.requested) }
    }
}
