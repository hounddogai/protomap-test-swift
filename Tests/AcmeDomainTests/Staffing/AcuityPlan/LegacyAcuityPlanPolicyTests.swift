@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanPolicyTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newLegacyAcuityPlanPolicy("code-231", label: "label-557")
        #expect(item.status == Staffing.LegacyAcuityPlanPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newLegacyAcuityPlanPolicy("code-231", label: "label-557")
        try item.moveTo(Staffing.LegacyAcuityPlanPolicyStatus.retired)
        #expect(item.status == Staffing.LegacyAcuityPlanPolicyStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newLegacyAcuityPlanPolicy("code-231", label: "label-557")
        item.status = Staffing.LegacyAcuityPlanPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyAcuityPlanPolicyStatus.created) }
    }
}
