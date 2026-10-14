@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapSnapshotTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        #expect(item.status == CareManagement.SeasonalCareGapSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        try item.moveTo(CareManagement.SeasonalCareGapSnapshotStatus.published)
        #expect(item.status == CareManagement.SeasonalCareGapSnapshotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        item.status = CareManagement.SeasonalCareGapSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapSnapshotStatus.created) }
    }
}
