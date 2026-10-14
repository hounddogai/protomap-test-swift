@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftRollupTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftRollup("code-807", label: "label-54")
        #expect(item.status == Staffing.ShiftRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newShiftRollup("code-807", label: "label-54")
        try item.moveTo(Staffing.ShiftRollupStatus.closed)
        #expect(item.status == Staffing.ShiftRollupStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftRollup("code-807", label: "label-54")
        item.status = Staffing.ShiftRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftRollupStatus.draft) }
    }
}
