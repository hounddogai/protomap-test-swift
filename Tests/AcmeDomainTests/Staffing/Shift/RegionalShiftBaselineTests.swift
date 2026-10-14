@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalShiftBaselineTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newRegionalShiftBaseline("code-44", name: "name-733")
        #expect(item.status == Staffing.RegionalShiftBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newRegionalShiftBaseline("code-44", name: "name-733")
        try item.moveTo(Staffing.RegionalShiftBaselineStatus.ready)
        #expect(item.status == Staffing.RegionalShiftBaselineStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newRegionalShiftBaseline("code-44", name: "name-733")
        item.status = Staffing.RegionalShiftBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalShiftBaselineStatus.idle) }
    }
}
