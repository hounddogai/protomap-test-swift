@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSnapshotTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newOrderSetSnapshot("code-165", name: "name-728")
        #expect(item.status == ClinicalOps.OrderSetSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newOrderSetSnapshot("code-165", name: "name-728")
        try item.moveTo(ClinicalOps.OrderSetSnapshotStatus.running)
        #expect(item.status == ClinicalOps.OrderSetSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newOrderSetSnapshot("code-165", name: "name-728")
        item.status = ClinicalOps.OrderSetSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetSnapshotStatus.new) }
    }
}
