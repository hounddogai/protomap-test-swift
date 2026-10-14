@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftRollupTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLegacyShiftRollup("code-426", name: "name-55")
        #expect(item.status == Staffing.LegacyShiftRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newLegacyShiftRollup("code-426", name: "name-55")
        try item.moveTo(Staffing.LegacyShiftRollupStatus.ready)
        #expect(item.status == Staffing.LegacyShiftRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLegacyShiftRollup("code-426", name: "name-55")
        item.status = Staffing.LegacyShiftRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyShiftRollupStatus.idle) }
    }
}
