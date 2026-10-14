@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingRuleTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRoundingRule("code-575", label: "label-833")
        #expect(item.status == ClinicalOps.RoundingRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRoundingRule("code-575", label: "label-833")
        try item.moveTo(ClinicalOps.RoundingRuleStatus.validated)
        #expect(item.status == ClinicalOps.RoundingRuleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRoundingRule("code-575", label: "label-833")
        item.status = ClinicalOps.RoundingRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingRuleStatus.created) }
    }
}
