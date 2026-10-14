@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newOvertimeMilestone("code-264", name: "name-497")
        #expect(item.status == Staffing.OvertimeMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newOvertimeMilestone("code-264", name: "name-497")
        try item.moveTo(Staffing.OvertimeMilestoneStatus.ready)
        #expect(item.status == Staffing.OvertimeMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newOvertimeMilestone("code-264", name: "name-497")
        item.status = Staffing.OvertimeMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeMilestoneStatus.idle) }
    }
}
