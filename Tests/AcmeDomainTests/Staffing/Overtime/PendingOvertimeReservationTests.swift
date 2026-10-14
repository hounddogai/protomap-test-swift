@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeReservationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        #expect(item.status == Staffing.PendingOvertimeReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        try item.moveTo(Staffing.PendingOvertimeReservationStatus.granted)
        #expect(item.status == Staffing.PendingOvertimeReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        item.status = Staffing.PendingOvertimeReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingOvertimeReservationStatus.requested) }
    }
}
