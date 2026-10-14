@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultAcuityPlanMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newDefaultAcuityPlanMilestone("code-573", title: "title-885")
        #expect(item.status == Staffing.DefaultAcuityPlanMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newDefaultAcuityPlanMilestone("code-573", title: "title-885")
        try item.moveTo(Staffing.DefaultAcuityPlanMilestoneStatus.published)
        #expect(item.status == Staffing.DefaultAcuityPlanMilestoneStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newDefaultAcuityPlanMilestone("code-573", title: "title-885")
        item.status = Staffing.DefaultAcuityPlanMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultAcuityPlanMilestoneStatus.created) }
    }
}
