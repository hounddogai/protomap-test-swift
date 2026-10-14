@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningPlanTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newScheduledCleaningPlan("code-317", title: "title-132")
        #expect(item.status == BedManagement.ScheduledCleaningPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newScheduledCleaningPlan("code-317", title: "title-132")
        try item.moveTo(BedManagement.ScheduledCleaningPlanStatus.warming)
        #expect(item.status == BedManagement.ScheduledCleaningPlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newScheduledCleaningPlan("code-317", title: "title-132")
        item.status = BedManagement.ScheduledCleaningPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCleaningPlanStatus.idle) }
    }
}
