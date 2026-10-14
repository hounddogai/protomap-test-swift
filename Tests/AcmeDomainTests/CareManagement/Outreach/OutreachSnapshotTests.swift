@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSnapshotTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachSnapshot("code-387", title: "title-891")
        #expect(item.status == CareManagement.OutreachSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newOutreachSnapshot("code-387", title: "title-891")
        try item.moveTo(CareManagement.OutreachSnapshotStatus.running)
        #expect(item.status == CareManagement.OutreachSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachSnapshot("code-387", title: "title-891")
        item.status = CareManagement.OutreachSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachSnapshotStatus.new) }
    }
}
