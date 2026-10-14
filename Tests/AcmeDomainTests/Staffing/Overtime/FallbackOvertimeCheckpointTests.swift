@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimeCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFallbackOvertimeCheckpoint("code-197", title: "title-175")
        #expect(item.status == Staffing.FallbackOvertimeCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newFallbackOvertimeCheckpoint("code-197", title: "title-175")
        try item.moveTo(Staffing.FallbackOvertimeCheckpointStatus.ready)
        #expect(item.status == Staffing.FallbackOvertimeCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFallbackOvertimeCheckpoint("code-197", title: "title-175")
        item.status = Staffing.FallbackOvertimeCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackOvertimeCheckpointStatus.idle) }
    }
}
