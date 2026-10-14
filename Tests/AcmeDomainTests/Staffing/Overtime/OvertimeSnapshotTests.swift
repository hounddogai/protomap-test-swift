@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSnapshotTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newOvertimeSnapshot("code-409", label: "label-115")
        #expect(item.status == Staffing.OvertimeSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newOvertimeSnapshot("code-409", label: "label-115")
        try item.moveTo(Staffing.OvertimeSnapshotStatus.draining)
        #expect(item.status == Staffing.OvertimeSnapshotStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newOvertimeSnapshot("code-409", label: "label-115")
        item.status = Staffing.OvertimeSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeSnapshotStatus.idle) }
    }
}
