@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newTieredAcuityPlanMilestone("code-452", name: "name-213")
        #expect(item.status == Staffing.TieredAcuityPlanMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newTieredAcuityPlanMilestone("code-452", name: "name-213")
        try item.moveTo(Staffing.TieredAcuityPlanMilestoneStatus.rejected)
        #expect(item.status == Staffing.TieredAcuityPlanMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newTieredAcuityPlanMilestone("code-452", name: "name-213")
        item.status = Staffing.TieredAcuityPlanMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredAcuityPlanMilestoneStatus.proposed) }
    }
}
