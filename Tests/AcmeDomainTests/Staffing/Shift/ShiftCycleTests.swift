@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCycleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newShiftCycle("code-669", name: "name-897")
        #expect(item.status == Staffing.ShiftCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newShiftCycle("code-669", name: "name-897")
        try item.moveTo(Staffing.ShiftCycleStatus.completed)
        #expect(item.status == Staffing.ShiftCycleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newShiftCycle("code-669", name: "name-897")
        item.status = Staffing.ShiftCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftCycleStatus.planned) }
    }
}
