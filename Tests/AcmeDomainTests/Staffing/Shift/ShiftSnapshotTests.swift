@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newShiftSnapshot("code-68", name: "name-488")
        #expect(item.status == Staffing.ShiftSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Staffing.newShiftSnapshot("code-68", name: "name-488")
        try item.moveTo(Staffing.ShiftSnapshotStatus.cancelled)
        #expect(item.status == Staffing.ShiftSnapshotStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newShiftSnapshot("code-68", name: "name-488")
        item.status = Staffing.ShiftSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftSnapshotStatus.planned) }
    }
}
