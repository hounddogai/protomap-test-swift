@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapSnapshotTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newScheduledCareGapSnapshot("code-508", title: "title-445")
        #expect(item.status == CareManagement.ScheduledCareGapSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newScheduledCareGapSnapshot("code-508", title: "title-445")
        try item.moveTo(CareManagement.ScheduledCareGapSnapshotStatus.published)
        #expect(item.status == CareManagement.ScheduledCareGapSnapshotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newScheduledCareGapSnapshot("code-508", title: "title-445")
        item.status = CareManagement.ScheduledCareGapSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledCareGapSnapshotStatus.created) }
    }
}
