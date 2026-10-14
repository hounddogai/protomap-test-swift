@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEstimateTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newAcuityPlanEstimate("code-423", label: "label-49")
        #expect(item.status == Staffing.AcuityPlanEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newAcuityPlanEstimate("code-423", label: "label-49")
        try item.moveTo(Staffing.AcuityPlanEstimateStatus.published)
        #expect(item.status == Staffing.AcuityPlanEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newAcuityPlanEstimate("code-423", label: "label-49")
        item.status = Staffing.AcuityPlanEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanEstimateStatus.created) }
    }
}
