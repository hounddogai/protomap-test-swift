@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictOrderSetRollupTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newStrictOrderSetRollup("code-374", label: "label-152")
        #expect(item.status == ClinicalOps.StrictOrderSetRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newStrictOrderSetRollup("code-374", label: "label-152")
        try item.moveTo(ClinicalOps.StrictOrderSetRollupStatus.warming)
        #expect(item.status == ClinicalOps.StrictOrderSetRollupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newStrictOrderSetRollup("code-374", label: "label-152")
        item.status = ClinicalOps.StrictOrderSetRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictOrderSetRollupStatus.idle) }
    }
}
