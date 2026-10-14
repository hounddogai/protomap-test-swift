@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveAcuityPlanScoreTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAdaptiveAcuityPlanScore("code-829", label: "label-59")
        #expect(item.status == Staffing.AdaptiveAcuityPlanScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newAdaptiveAcuityPlanScore("code-829", label: "label-59")
        try item.moveTo(Staffing.AdaptiveAcuityPlanScoreStatus.queued)
        #expect(item.status == Staffing.AdaptiveAcuityPlanScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAdaptiveAcuityPlanScore("code-829", label: "label-59")
        item.status = Staffing.AdaptiveAcuityPlanScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveAcuityPlanScoreStatus.new) }
    }
}
