@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftPlanTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftPlan("code-23", name: "name-21")
        #expect(item.status == Staffing.ShiftPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newShiftPlan("code-23", name: "name-21")
        try item.moveTo(Staffing.ShiftPlanStatus.queued)
        #expect(item.status == Staffing.ShiftPlanStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftPlan("code-23", name: "name-21")
        item.status = Staffing.ShiftPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftPlanStatus.new) }
    }
}
