@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newDefaultShiftAllocation("code-147", name: "name-101")
        #expect(item.status == Staffing.DefaultShiftAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newDefaultShiftAllocation("code-147", name: "name-101")
        try item.moveTo(Staffing.DefaultShiftAllocationStatus.scheduled)
        #expect(item.status == Staffing.DefaultShiftAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newDefaultShiftAllocation("code-147", name: "name-101")
        item.status = Staffing.DefaultShiftAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultShiftAllocationStatus.planned) }
    }
}
