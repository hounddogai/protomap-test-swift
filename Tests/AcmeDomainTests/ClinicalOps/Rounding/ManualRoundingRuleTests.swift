@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualRoundingRuleTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newManualRoundingRule("code-549", title: "title-624")
        #expect(item.status == ClinicalOps.ManualRoundingRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newManualRoundingRule("code-549", title: "title-624")
        try item.moveTo(ClinicalOps.ManualRoundingRuleStatus.warming)
        #expect(item.status == ClinicalOps.ManualRoundingRuleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newManualRoundingRule("code-549", title: "title-624")
        item.status = ClinicalOps.ManualRoundingRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualRoundingRuleStatus.idle) }
    }
}
