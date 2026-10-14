@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanPolicyTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimaryAcuityPlanPolicy("code-870", label: "label-10")
        #expect(item.status == Staffing.PrimaryAcuityPlanPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newPrimaryAcuityPlanPolicy("code-870", label: "label-10")
        try item.moveTo(Staffing.PrimaryAcuityPlanPolicyStatus.rejected)
        #expect(item.status == Staffing.PrimaryAcuityPlanPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimaryAcuityPlanPolicy("code-870", label: "label-10")
        item.status = Staffing.PrimaryAcuityPlanPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanPolicyStatus.proposed) }
    }
}
