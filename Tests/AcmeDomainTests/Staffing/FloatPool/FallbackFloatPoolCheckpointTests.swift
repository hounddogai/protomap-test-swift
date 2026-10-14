@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolCheckpointTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFallbackFloatPoolCheckpoint("code-856", label: "label-390")
        #expect(item.status == Staffing.FallbackFloatPoolCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newFallbackFloatPoolCheckpoint("code-856", label: "label-390")
        try item.moveTo(Staffing.FallbackFloatPoolCheckpointStatus.queued)
        #expect(item.status == Staffing.FallbackFloatPoolCheckpointStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFallbackFloatPoolCheckpoint("code-856", label: "label-390")
        item.status = Staffing.FallbackFloatPoolCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackFloatPoolCheckpointStatus.new) }
    }
}
