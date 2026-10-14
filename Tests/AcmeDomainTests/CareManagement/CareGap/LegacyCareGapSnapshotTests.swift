@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapSnapshotTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newLegacyCareGapSnapshot("code-520", label: "label-791")
        #expect(item.status == CareManagement.LegacyCareGapSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newLegacyCareGapSnapshot("code-520", label: "label-791")
        try item.moveTo(CareManagement.LegacyCareGapSnapshotStatus.active)
        #expect(item.status == CareManagement.LegacyCareGapSnapshotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newLegacyCareGapSnapshot("code-520", label: "label-791")
        item.status = CareManagement.LegacyCareGapSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyCareGapSnapshotStatus.draft) }
    }
}
