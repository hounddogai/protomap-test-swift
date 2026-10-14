@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanPolicyTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newAcuityPlanPolicy("code-421", label: "label-651")
        #expect(item.status == Staffing.AcuityPlanPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newAcuityPlanPolicy("code-421", label: "label-651")
        try item.moveTo(Staffing.AcuityPlanPolicyStatus.validated)
        #expect(item.status == Staffing.AcuityPlanPolicyStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newAcuityPlanPolicy("code-421", label: "label-651")
        item.status = Staffing.AcuityPlanPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanPolicyStatus.created) }
    }
}
