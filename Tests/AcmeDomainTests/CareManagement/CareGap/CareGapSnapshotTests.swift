@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapSnapshotTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCareGapSnapshot("code-369", name: "name-804")
        #expect(item.status == CareManagement.CareGapSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newCareGapSnapshot("code-369", name: "name-804")
        try item.moveTo(CareManagement.CareGapSnapshotStatus.running)
        #expect(item.status == CareManagement.CareGapSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCareGapSnapshot("code-369", name: "name-804")
        item.status = CareManagement.CareGapSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapSnapshotStatus.new) }
    }
}
