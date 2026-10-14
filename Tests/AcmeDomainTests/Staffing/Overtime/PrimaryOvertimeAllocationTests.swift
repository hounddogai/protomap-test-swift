@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeAllocationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimaryOvertimeAllocation("code-192", title: "title-199")
        #expect(item.status == Staffing.PrimaryOvertimeAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newPrimaryOvertimeAllocation("code-192", title: "title-199")
        try item.moveTo(Staffing.PrimaryOvertimeAllocationStatus.approved)
        #expect(item.status == Staffing.PrimaryOvertimeAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimaryOvertimeAllocation("code-192", title: "title-199")
        item.status = Staffing.PrimaryOvertimeAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryOvertimeAllocationStatus.proposed) }
    }
}
