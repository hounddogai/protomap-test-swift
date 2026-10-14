@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPlanTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newOrderSetPlan("code-266", title: "title-19")
        #expect(item.status == ClinicalOps.OrderSetPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newOrderSetPlan("code-266", title: "title-19")
        try item.moveTo(ClinicalOps.OrderSetPlanStatus.resolved)
        #expect(item.status == ClinicalOps.OrderSetPlanStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newOrderSetPlan("code-266", title: "title-19")
        item.status = ClinicalOps.OrderSetPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetPlanStatus.`open`) }
    }
}
