@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftCheckpoint("code-16", label: "label-523")
        #expect(item.status == Staffing.ShiftCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newShiftCheckpoint("code-16", label: "label-523")
        try item.moveTo(Staffing.ShiftCheckpointStatus.closed)
        #expect(item.status == Staffing.ShiftCheckpointStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftCheckpoint("code-16", label: "label-523")
        item.status = Staffing.ShiftCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftCheckpointStatus.draft) }
    }
}
