@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolCheckpoint("code-791", label: "label-587")
        #expect(item.status == Staffing.FloatPoolCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newFloatPoolCheckpoint("code-791", label: "label-587")
        try item.moveTo(Staffing.FloatPoolCheckpointStatus.pending)
        #expect(item.status == Staffing.FloatPoolCheckpointStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolCheckpoint("code-791", label: "label-587")
        item.status = Staffing.FloatPoolCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolCheckpointStatus.draft) }
    }
}
