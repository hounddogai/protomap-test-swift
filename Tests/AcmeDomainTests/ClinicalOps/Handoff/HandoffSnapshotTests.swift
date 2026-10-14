@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSnapshotTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newHandoffSnapshot("code-338", name: "name-350")
        #expect(item.status == ClinicalOps.HandoffSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newHandoffSnapshot("code-338", name: "name-350")
        try item.moveTo(ClinicalOps.HandoffSnapshotStatus.withdrawn)
        #expect(item.status == ClinicalOps.HandoffSnapshotStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newHandoffSnapshot("code-338", name: "name-350")
        item.status = ClinicalOps.HandoffSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffSnapshotStatus.proposed) }
    }
}
