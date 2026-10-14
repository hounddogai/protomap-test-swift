@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRollupTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newAcuityPlanRollup("code-788", title: "title-380")
        #expect(item.status == Staffing.AcuityPlanRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newAcuityPlanRollup("code-788", title: "title-380")
        try item.moveTo(Staffing.AcuityPlanRollupStatus.draining)
        #expect(item.status == Staffing.AcuityPlanRollupStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newAcuityPlanRollup("code-788", title: "title-380")
        item.status = Staffing.AcuityPlanRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanRollupStatus.idle) }
    }
}
