@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeReservationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        #expect(item.status == Staffing.BatchedOvertimeReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        try item.moveTo(Staffing.BatchedOvertimeReservationStatus.approved)
        #expect(item.status == Staffing.BatchedOvertimeReservationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        item.status = Staffing.BatchedOvertimeReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedOvertimeReservationStatus.proposed) }
    }
}
