@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationScheduleTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newStrictIsolationSchedule("code-666", label: "label-17")
        #expect(item.status == BedManagement.StrictIsolationScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newStrictIsolationSchedule("code-666", label: "label-17")
        try item.moveTo(BedManagement.StrictIsolationScheduleStatus.pending)
        #expect(item.status == BedManagement.StrictIsolationScheduleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newStrictIsolationSchedule("code-666", label: "label-17")
        item.status = BedManagement.StrictIsolationScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictIsolationScheduleStatus.draft) }
    }
}
