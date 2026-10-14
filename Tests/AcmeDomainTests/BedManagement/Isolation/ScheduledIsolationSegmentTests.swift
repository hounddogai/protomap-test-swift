@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationSegmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newScheduledIsolationSegment("code-22", name: "name-78")
        #expect(item.status == BedManagement.ScheduledIsolationSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newScheduledIsolationSegment("code-22", name: "name-78")
        try item.moveTo(BedManagement.ScheduledIsolationSegmentStatus.active)
        #expect(item.status == BedManagement.ScheduledIsolationSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newScheduledIsolationSegment("code-22", name: "name-78")
        item.status = BedManagement.ScheduledIsolationSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledIsolationSegmentStatus.draft) }
    }
}
