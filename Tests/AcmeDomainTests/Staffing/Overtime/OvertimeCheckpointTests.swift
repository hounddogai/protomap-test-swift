@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newOvertimeCheckpoint("code-394", label: "label-714")
        #expect(item.status == Staffing.OvertimeCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newOvertimeCheckpoint("code-394", label: "label-714")
        try item.moveTo(Staffing.OvertimeCheckpointStatus.warming)
        #expect(item.status == Staffing.OvertimeCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newOvertimeCheckpoint("code-394", label: "label-714")
        item.status = Staffing.OvertimeCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeCheckpointStatus.idle) }
    }
}
