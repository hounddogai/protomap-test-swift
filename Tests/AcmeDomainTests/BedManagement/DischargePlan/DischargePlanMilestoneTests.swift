@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanMilestoneTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newDischargePlanMilestone("code-921", title: "title-357")
        #expect(item.status == BedManagement.DischargePlanMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newDischargePlanMilestone("code-921", title: "title-357")
        try item.moveTo(BedManagement.DischargePlanMilestoneStatus.inReview)
        #expect(item.status == BedManagement.DischargePlanMilestoneStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newDischargePlanMilestone("code-921", title: "title-357")
        item.status = BedManagement.DischargePlanMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanMilestoneStatus.`open`) }
    }
}
