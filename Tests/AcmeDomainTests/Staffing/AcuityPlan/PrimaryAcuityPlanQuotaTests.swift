@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanQuotaTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimaryAcuityPlanQuota("code-820", label: "label-727")
        #expect(item.status == Staffing.PrimaryAcuityPlanQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newPrimaryAcuityPlanQuota("code-820", label: "label-727")
        try item.moveTo(Staffing.PrimaryAcuityPlanQuotaStatus.rejected)
        #expect(item.status == Staffing.PrimaryAcuityPlanQuotaStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimaryAcuityPlanQuota("code-820", label: "label-727")
        item.status = Staffing.PrimaryAcuityPlanQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanQuotaStatus.proposed) }
    }
}
