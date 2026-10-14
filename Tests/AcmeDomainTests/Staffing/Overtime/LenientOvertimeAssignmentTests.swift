@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientOvertimeAssignmentTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLenientOvertimeAssignment("code-775", title: "title-961")
        #expect(item.status == Staffing.LenientOvertimeAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newLenientOvertimeAssignment("code-775", title: "title-961")
        try item.moveTo(Staffing.LenientOvertimeAssignmentStatus.running)
        #expect(item.status == Staffing.LenientOvertimeAssignmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLenientOvertimeAssignment("code-775", title: "title-961")
        item.status = Staffing.LenientOvertimeAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientOvertimeAssignmentStatus.new) }
    }
}
