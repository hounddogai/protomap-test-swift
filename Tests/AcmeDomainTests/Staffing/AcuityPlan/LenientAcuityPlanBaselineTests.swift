@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanBaselineTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLenientAcuityPlanBaseline("code-328", label: "label-212")
        #expect(item.status == Staffing.LenientAcuityPlanBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newLenientAcuityPlanBaseline("code-328", label: "label-212")
        try item.moveTo(Staffing.LenientAcuityPlanBaselineStatus.draining)
        #expect(item.status == Staffing.LenientAcuityPlanBaselineStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLenientAcuityPlanBaseline("code-328", label: "label-212")
        item.status = Staffing.LenientAcuityPlanBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientAcuityPlanBaselineStatus.idle) }
    }
}
