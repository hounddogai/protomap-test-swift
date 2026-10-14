@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSnapshotTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskSnapshot("code-550", label: "label-509")
        #expect(item.status == ClinicalOps.TaskSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newTaskSnapshot("code-550", label: "label-509")
        try item.moveTo(ClinicalOps.TaskSnapshotStatus.running)
        #expect(item.status == ClinicalOps.TaskSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskSnapshot("code-550", label: "label-509")
        item.status = ClinicalOps.TaskSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskSnapshotStatus.new) }
    }
}
