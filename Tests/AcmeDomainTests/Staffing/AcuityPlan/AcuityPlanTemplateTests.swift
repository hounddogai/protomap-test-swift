@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanTemplateTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAcuityPlanTemplate("code-713", label: "label-301")
        #expect(item.status == Staffing.AcuityPlanTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newAcuityPlanTemplate("code-713", label: "label-301")
        try item.moveTo(Staffing.AcuityPlanTemplateStatus.withdrawn)
        #expect(item.status == Staffing.AcuityPlanTemplateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAcuityPlanTemplate("code-713", label: "label-301")
        item.status = Staffing.AcuityPlanTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanTemplateStatus.proposed) }
    }
}
