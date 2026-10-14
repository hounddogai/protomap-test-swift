@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingAcuityPlanMilestoneTests {
    @Test func startsInNew() throws {
        let item = Staffing.newPendingAcuityPlanMilestone("code-211", label: "label-559")
        #expect(item.status == Staffing.PendingAcuityPlanMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newPendingAcuityPlanMilestone("code-211", label: "label-559")
        try item.moveTo(Staffing.PendingAcuityPlanMilestoneStatus.running)
        #expect(item.status == Staffing.PendingAcuityPlanMilestoneStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newPendingAcuityPlanMilestone("code-211", label: "label-559")
        item.status = Staffing.PendingAcuityPlanMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingAcuityPlanMilestoneStatus.new) }
    }
}
