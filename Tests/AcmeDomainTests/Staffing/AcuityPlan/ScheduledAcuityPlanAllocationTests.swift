@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanAllocationTests {
    @Test func startsInNew() throws {
        let item = Staffing.newScheduledAcuityPlanAllocation("code-975", label: "label-735")
        #expect(item.status == Staffing.ScheduledAcuityPlanAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newScheduledAcuityPlanAllocation("code-975", label: "label-735")
        try item.moveTo(Staffing.ScheduledAcuityPlanAllocationStatus.running)
        #expect(item.status == Staffing.ScheduledAcuityPlanAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newScheduledAcuityPlanAllocation("code-975", label: "label-735")
        item.status = Staffing.ScheduledAcuityPlanAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledAcuityPlanAllocationStatus.new) }
    }
}
