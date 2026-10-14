@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSlotTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftSlot("code-992", name: "name-951")
        #expect(item.status == Staffing.ShiftSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newShiftSlot("code-992", name: "name-951")
        try item.moveTo(Staffing.ShiftSlotStatus.running)
        #expect(item.status == Staffing.ShiftSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftSlot("code-992", name: "name-951")
        item.status = Staffing.ShiftSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftSlotStatus.new) }
    }
}
