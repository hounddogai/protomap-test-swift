@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanTargetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAcuityPlanTarget("code-250", title: "title-299")
        #expect(item.status == Staffing.AcuityPlanTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newAcuityPlanTarget("code-250", title: "title-299")
        try item.moveTo(Staffing.AcuityPlanTargetStatus.approved)
        #expect(item.status == Staffing.AcuityPlanTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAcuityPlanTarget("code-250", title: "title-299")
        item.status = Staffing.AcuityPlanTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanTargetStatus.proposed) }
    }
}
