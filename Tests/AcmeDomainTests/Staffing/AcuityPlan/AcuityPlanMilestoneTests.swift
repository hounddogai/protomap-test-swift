@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newAcuityPlanMilestone("code-871", label: "label-474")
        #expect(item.status == Staffing.AcuityPlanMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newAcuityPlanMilestone("code-871", label: "label-474")
        try item.moveTo(Staffing.AcuityPlanMilestoneStatus.warming)
        #expect(item.status == Staffing.AcuityPlanMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newAcuityPlanMilestone("code-871", label: "label-474")
        item.status = Staffing.AcuityPlanMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanMilestoneStatus.idle) }
    }
}
