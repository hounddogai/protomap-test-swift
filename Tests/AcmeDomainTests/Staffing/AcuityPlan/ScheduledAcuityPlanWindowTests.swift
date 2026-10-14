@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanWindowTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newScheduledAcuityPlanWindow("code-991", title: "title-703")
        #expect(item.status == Staffing.ScheduledAcuityPlanWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newScheduledAcuityPlanWindow("code-991", title: "title-703")
        try item.moveTo(Staffing.ScheduledAcuityPlanWindowStatus.rejected)
        #expect(item.status == Staffing.ScheduledAcuityPlanWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newScheduledAcuityPlanWindow("code-991", title: "title-703")
        item.status = Staffing.ScheduledAcuityPlanWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledAcuityPlanWindowStatus.proposed) }
    }
}
