@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeAllocationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newBatchedOvertimeAllocation("code-726", title: "title-414")
        #expect(item.status == Staffing.BatchedOvertimeAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newBatchedOvertimeAllocation("code-726", title: "title-414")
        try item.moveTo(Staffing.BatchedOvertimeAllocationStatus.approved)
        #expect(item.status == Staffing.BatchedOvertimeAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newBatchedOvertimeAllocation("code-726", title: "title-414")
        item.status = Staffing.BatchedOvertimeAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedOvertimeAllocationStatus.proposed) }
    }
}
