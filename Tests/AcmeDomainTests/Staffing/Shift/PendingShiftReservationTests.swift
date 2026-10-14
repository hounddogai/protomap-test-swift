@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftReservationTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newPendingShiftReservation("code-545", label: "label-756")
        #expect(item.status == Staffing.PendingShiftReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newPendingShiftReservation("code-545", label: "label-756")
        try item.moveTo(Staffing.PendingShiftReservationStatus.suspended)
        #expect(item.status == Staffing.PendingShiftReservationStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newPendingShiftReservation("code-545", label: "label-756")
        item.status = Staffing.PendingShiftReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingShiftReservationStatus.draft) }
    }
}
