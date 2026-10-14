@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSlotTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeSlot("code-126", name: "name-639")
        #expect(item.status == Staffing.OvertimeSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newOvertimeSlot("code-126", name: "name-639")
        try item.moveTo(Staffing.OvertimeSlotStatus.active)
        #expect(item.status == Staffing.OvertimeSlotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeSlot("code-126", name: "name-639")
        item.status = Staffing.OvertimeSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeSlotStatus.draft) }
    }
}
