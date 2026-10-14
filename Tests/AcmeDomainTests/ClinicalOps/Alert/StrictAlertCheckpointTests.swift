@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictAlertCheckpointTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newStrictAlertCheckpoint("code-995", name: "name-343")
        #expect(item.status == ClinicalOps.StrictAlertCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newStrictAlertCheckpoint("code-995", name: "name-343")
        try item.moveTo(ClinicalOps.StrictAlertCheckpointStatus.running)
        #expect(item.status == ClinicalOps.StrictAlertCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newStrictAlertCheckpoint("code-995", name: "name-343")
        item.status = ClinicalOps.StrictAlertCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictAlertCheckpointStatus.new) }
    }
}
