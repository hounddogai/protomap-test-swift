@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanEntryTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newTieredAcuityPlanEntry("code-609", name: "name-367")
        #expect(item.status == Staffing.TieredAcuityPlanEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newTieredAcuityPlanEntry("code-609", name: "name-367")
        try item.moveTo(Staffing.TieredAcuityPlanEntryStatus.warming)
        #expect(item.status == Staffing.TieredAcuityPlanEntryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newTieredAcuityPlanEntry("code-609", name: "name-367")
        item.status = Staffing.TieredAcuityPlanEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredAcuityPlanEntryStatus.idle) }
    }
}
