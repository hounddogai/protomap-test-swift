@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationSegmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newLegacyIsolationSegment("code-374", title: "title-576")
        #expect(item.status == BedManagement.LegacyIsolationSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newLegacyIsolationSegment("code-374", title: "title-576")
        try item.moveTo(BedManagement.LegacyIsolationSegmentStatus.pending)
        #expect(item.status == BedManagement.LegacyIsolationSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newLegacyIsolationSegment("code-374", title: "title-576")
        item.status = BedManagement.LegacyIsolationSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyIsolationSegmentStatus.draft) }
    }
}
