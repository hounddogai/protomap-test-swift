@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRuleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetRule("code-330", name: "name-932")
        #expect(item.status == ClinicalOps.OrderSetRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newOrderSetRule("code-330", name: "name-932")
        try item.moveTo(ClinicalOps.OrderSetRuleStatus.inProgress)
        #expect(item.status == ClinicalOps.OrderSetRuleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetRule("code-330", name: "name-932")
        item.status = ClinicalOps.OrderSetRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetRuleStatus.planned) }
    }
}
