@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCycleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newOvertimeCycle("code-549", label: "label-80")
        #expect(item.status == Staffing.OvertimeCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newOvertimeCycle("code-549", label: "label-80")
        try item.moveTo(Staffing.OvertimeCycleStatus.warming)
        #expect(item.status == Staffing.OvertimeCycleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newOvertimeCycle("code-549", label: "label-80")
        item.status = Staffing.OvertimeCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeCycleStatus.idle) }
    }
}
