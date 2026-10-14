@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetRuleTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newWeightedOrderSetRule("code-148", name: "name-751")
        #expect(item.status == ClinicalOps.WeightedOrderSetRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newWeightedOrderSetRule("code-148", name: "name-751")
        try item.moveTo(ClinicalOps.WeightedOrderSetRuleStatus.revoked)
        #expect(item.status == ClinicalOps.WeightedOrderSetRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newWeightedOrderSetRule("code-148", name: "name-751")
        item.status = ClinicalOps.WeightedOrderSetRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedOrderSetRuleStatus.requested) }
    }
}
