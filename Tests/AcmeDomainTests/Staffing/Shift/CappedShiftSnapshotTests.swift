@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCappedShiftSnapshot("code-87", label: "label-771")
        #expect(item.status == Staffing.CappedShiftSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newCappedShiftSnapshot("code-87", label: "label-771")
        try item.moveTo(Staffing.CappedShiftSnapshotStatus.validated)
        #expect(item.status == Staffing.CappedShiftSnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCappedShiftSnapshot("code-87", label: "label-771")
        item.status = Staffing.CappedShiftSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedShiftSnapshotStatus.created) }
    }
}
