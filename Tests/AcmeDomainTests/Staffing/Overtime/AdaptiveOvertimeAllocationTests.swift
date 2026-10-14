@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAllocationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAdaptiveOvertimeAllocation("code-18", name: "name-427")
        #expect(item.status == Staffing.AdaptiveOvertimeAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newAdaptiveOvertimeAllocation("code-18", name: "name-427")
        try item.moveTo(Staffing.AdaptiveOvertimeAllocationStatus.approved)
        #expect(item.status == Staffing.AdaptiveOvertimeAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAdaptiveOvertimeAllocation("code-18", name: "name-427")
        item.status = Staffing.AdaptiveOvertimeAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveOvertimeAllocationStatus.proposed) }
    }
}
