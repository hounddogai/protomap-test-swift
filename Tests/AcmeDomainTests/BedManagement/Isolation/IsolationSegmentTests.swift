@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSegmentTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newIsolationSegment("code-105", title: "title-424")
        #expect(item.status == BedManagement.IsolationSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newIsolationSegment("code-105", title: "title-424")
        try item.moveTo(BedManagement.IsolationSegmentStatus.inProgress)
        #expect(item.status == BedManagement.IsolationSegmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newIsolationSegment("code-105", title: "title-424")
        item.status = BedManagement.IsolationSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationSegmentStatus.planned) }
    }
}
