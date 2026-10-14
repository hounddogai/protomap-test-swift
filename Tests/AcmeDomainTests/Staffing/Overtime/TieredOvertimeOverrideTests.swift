@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeOverrideTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newTieredOvertimeOverride("code-982", name: "name-735")
        #expect(item.status == Staffing.TieredOvertimeOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newTieredOvertimeOverride("code-982", name: "name-735")
        try item.moveTo(Staffing.TieredOvertimeOverrideStatus.warming)
        #expect(item.status == Staffing.TieredOvertimeOverrideStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newTieredOvertimeOverride("code-982", name: "name-735")
        item.status = Staffing.TieredOvertimeOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredOvertimeOverrideStatus.idle) }
    }
}
