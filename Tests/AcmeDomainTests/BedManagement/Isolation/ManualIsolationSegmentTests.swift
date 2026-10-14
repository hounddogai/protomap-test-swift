@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationSegmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newManualIsolationSegment("code-953", name: "name-443")
        #expect(item.status == BedManagement.ManualIsolationSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newManualIsolationSegment("code-953", name: "name-443")
        try item.moveTo(BedManagement.ManualIsolationSegmentStatus.active)
        #expect(item.status == BedManagement.ManualIsolationSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newManualIsolationSegment("code-953", name: "name-443")
        item.status = BedManagement.ManualIsolationSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualIsolationSegmentStatus.draft) }
    }
}
