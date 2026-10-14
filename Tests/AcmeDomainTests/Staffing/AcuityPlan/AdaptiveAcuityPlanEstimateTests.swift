@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveAcuityPlanEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAdaptiveAcuityPlanEstimate("code-865", label: "label-687")
        #expect(item.status == Staffing.AdaptiveAcuityPlanEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newAdaptiveAcuityPlanEstimate("code-865", label: "label-687")
        try item.moveTo(Staffing.AdaptiveAcuityPlanEstimateStatus.completed)
        #expect(item.status == Staffing.AdaptiveAcuityPlanEstimateStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAdaptiveAcuityPlanEstimate("code-865", label: "label-687")
        item.status = Staffing.AdaptiveAcuityPlanEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveAcuityPlanEstimateStatus.planned) }
    }
}
