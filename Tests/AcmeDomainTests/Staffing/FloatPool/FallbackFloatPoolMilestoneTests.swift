@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFallbackFloatPoolMilestone("code-45", name: "name-414")
        #expect(item.status == Staffing.FallbackFloatPoolMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newFallbackFloatPoolMilestone("code-45", name: "name-414")
        try item.moveTo(Staffing.FallbackFloatPoolMilestoneStatus.ready)
        #expect(item.status == Staffing.FallbackFloatPoolMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFallbackFloatPoolMilestone("code-45", name: "name-414")
        item.status = Staffing.FallbackFloatPoolMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackFloatPoolMilestoneStatus.idle) }
    }
}
