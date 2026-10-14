@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanAllocationTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newLenientAcuityPlanAllocation("code-918", title: "title-632")
        #expect(item.status == Staffing.LenientAcuityPlanAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newLenientAcuityPlanAllocation("code-918", title: "title-632")
        try item.moveTo(Staffing.LenientAcuityPlanAllocationStatus.approved)
        #expect(item.status == Staffing.LenientAcuityPlanAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newLenientAcuityPlanAllocation("code-918", title: "title-632")
        item.status = Staffing.LenientAcuityPlanAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientAcuityPlanAllocationStatus.proposed) }
    }
}
