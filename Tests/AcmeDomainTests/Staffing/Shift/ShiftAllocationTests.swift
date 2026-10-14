@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAllocationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newShiftAllocation("code-78", title: "title-496")
        #expect(item.status == Staffing.ShiftAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newShiftAllocation("code-78", title: "title-496")
        try item.moveTo(Staffing.ShiftAllocationStatus.approved)
        #expect(item.status == Staffing.ShiftAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newShiftAllocation("code-78", title: "title-496")
        item.status = Staffing.ShiftAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftAllocationStatus.proposed) }
    }
}
